-- See LICENSE for more info about your rights as a person to be
-- rightfully persecuted

export script_name        = "Aegisub-Motion"
export script_description = "A set of tools for simplifying the process of creating and applying motion tracking data with Aegisub."
export script_author      = "torque"
export script_version     = "##__AEGISUB-MOTION_VERSION__##"
export script_namespace   = "a-mo.Aegisub-Motion"

local interface, setProgress, setTask
local versionRecord, clipboard, json, ConfigHandler, DataWrapper
local LineCollection, log, Math, MotionHandler, Statistics, TrimHandler, Tags

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

if haveDepCtrl
	versionRecord = DependencyControl {
		url: 'https://github.com/TypesettingTools/Aegisub-Motion'
		feed: 'https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json'
		{
			'aegisub.clipboard'
			'json'
			{ 'a-mo.ConfigHandler',  version: '##__CONFIGHANDLER_VERSION__##'  }
			{ 'a-mo.DataWrapper',    version: '##__DATAWRAPPER_VERSION__##'    }
			{ 'a-mo.LineCollection', version: '##__LINECOLLECTION_VERSION__##' }
			{ 'a-mo.Log' ,           version: '##__LOG_VERSION__##'            }
			{ 'a-mo.Math' ,          version: '##__MATH_VERSION__##'           }
			{ 'a-mo.MotionHandler',  version: '##__MOTIONHANDLER_VERSION__##'  }
			{ 'a-mo.Statistics' ,    version: '##__STATISTICS_VERSION__##'     }
			{ 'a-mo.TrimHandler',    version: '##__TRIMHANDLER_VERSION__##'    }
			{ 'a-mo.Tags',           version: '##__TAGS_VERSION__##'           }
		}
	}
	clipboard, json, ConfigHandler, DataWrapper, LineCollection, log, Math, MotionHandler, Statistics, TrimHandler, Tags = versionRecord\requireModules!

else
	clipboard      = require 'aegisub.clipboard'
	json           = require 'json'
	ConfigHandler  = require 'a-mo.ConfigHandler'
	DataWrapper    = require 'a-mo.DataWrapper'
	LineCollection = require 'a-mo.LineCollection'
	log            = require 'a-mo.Log'
	Math           = require 'a-mo.Math'
	MotionHandler  = require 'a-mo.MotionHandler'
	Statistics     = require 'a-mo.Statistics'
	TrimHandler    = require 'a-mo.TrimHandler'
	Tags           = require 'a-mo.Tags'

statsTemplate = {
	apply: {
		longestTrack: 0
		lines: { largestInput: 0, largestOutput: 0, totalOutput: 0 }
		bytes: { largestInput: 0, largestOutput: 0, totalOutput: 0 }
		runCount: 0
	}
	trim: {
		runCount: 0
		clipsCreated: 0
	}
	trimEach: {
		runCount: 0
	}
	revert: {
		lines: { total: 0 }
		bytes: { total: 0 }
		runCount: 0
	}
	uuid: 0
}

initStats = ->
	stats = Statistics statsTemplate, "aegisub-motion.stats.json"
	if 0 == stats\getValue "uuid"
		stats\setValue "uuid", Math.uuid!
		stats\write!

	return stats

initializeInterface = ->
	-- Set up interface tables.
	interface = {
		main: {
			-- mnemonics: xyOCSBuRWen + G\A + Wl\A
			dataLabel: { class: "label",    x: 0, y: 0,  width: 10, height: 1,                                  label: "                 Paste data or enter a filepath." }
			data:      { class: "textbox",  x: 0, y: 1,  width: 10, height: 4,                                                     hint: "Paste data or the path to a file containing it. No quotes or escapes." }

			-- optLabel:  { class: "label",    x: 0, y: 5,  width: 5,  height: 1,                                  label: "Data to be applied:" }
			xPosition: { class: "checkbox", x: 0, y: 5,  width: 1,  height: 1, config: true, label: "&x",            value: true,  hint: "Apply x position data to the selected lines." }
			yPosition: { class: "checkbox", x: 1, y: 5,  width: 1,  height: 1, config: true, label: "&y",            value: true,  hint: "Apply y position data to the selected lines." }
			origin:    { class: "checkbox", x: 2, y: 5,  width: 2,  height: 1, config: true, label: "&Origin",       value: false, hint: "Move the origin along with the position." }
			absPos:    { class: "checkbox", x: 4, y: 5,  width: 2,  height: 1, config: true, label: "Absolut&e",     value: false, hint: "Set position to exactly that of the tracking data with no processing." }

			xScale:    { class: "checkbox", x: 0, y: 6,  width: 2,  height: 1, config: true, label: "&Scale",        value: true,  hint: "Apply scaling data to the selected lines." }
			border:    { class: "checkbox", x: 2, y: 6,  width: 2,  height: 1, config: true, label: "&Border",       value: true,  hint: "Scale border with the line (only if Scale is also selected)." }
			shadow:    { class: "checkbox", x: 4, y: 6,  width: 2,  height: 1, config: true, label: "&Shadow",       value: true,  hint: "Scale shadow with the line (only if Scale is also selected)." }
			blur:      { class: "checkbox", x: 4, y: 7,  width: 2,  height: 1, config: true, label: "Bl&ur",         value: true,  hint: "Scale blur with the line (only if Scale is also selected, does not scale \\be)." }
			blurScale: { class:"floatedit", x: 7, y: 7,  width: 2,  height: 1, config: true, step: 0.01,             value: 1,     hint: "Factor to attenuate (or amplify) blur values by." }

			zRotation: { class: "checkbox", x: 0, y: 7,  width: 3,  height: 1, config: true, label: "&Rotation",     value: false, hint: "Apply rotation data to the selected lines." }

			writeConf: { class: "checkbox", x: 0, y: 10, width: 4,  height: 1, config: true, label: "&Write config", value: true,  hint: "Write current settings to the configuration file." }
			relative:  { class: "checkbox", x: 4, y: 10, width: 3,  height: 1, config: true, label: "Relat&ive",     value: true,  hint: "Start frame should be relative to the beginning of the selection rather than the beginning of the video." }
			startFrame:{ class: "intedit",  x: 7, y: 10, width: 2,  height: 1, config: true,                         value: 1,     hint: "Frame used as the starting point for the tracking data. \"-1\" corresponds to the last frame." }
			linear:    { class: "checkbox", x: 4, y: 11, width: 2,  height: 1, config: true, label: "Li&near",       value: false, hint: "Use transforms and \\move to create a linear transition, instead of frame-by-frame." }
			clipOnly:  { class: "checkbox", x: 0, y: 11, width: 3,  height: 1, config: true, label: "&Clip Only",    value: false, hint: "Only apply the main data to \\clips present in the line." }

			rectClip:  { class: "checkbox", x: 0, y: 8,  width: 3,  height: 1, config: true, label: "Rect C&lip",    value: true,  hint: "Apply tracking data to the rectangular clip contained in the line." }
			vectClip:  { class: "checkbox", x: 3, y: 8,  width: 3,  height: 1, config: true, label: "&Vect Clip",    value: true,  hint: "Apply tracking data to the vector clip contained in the line." }
			rcToVc:    { class: "checkbox", x: 6, y: 8,  width: 4,  height: 1, config: true, label: "Rect -> Vect",  value: false, hint: "Convert rectangular clips contained in the line to vector clips." }
			killTrans: { class: "checkbox", x: 0, y: 9,  width: 10, height: 1, config: true, label: "Interpolate &transforms", value: true, hint: "Attempt to interpolate transform value instead of just shifting transform times." }
		}
		clip: {
			-- mnemonics: xySRe + GCA
			dataLabel: { class: "label",    x: 0, y: 0, width: 10, height: 1, label:  "                     This stuff is for clips." }
			data:      { class: "textbox",  x: 0, y: 1, width: 10, height: 4,               name:  "data", hint: "Paste data or the path to a file containing it. No quotes or escapes." }

			optLabel:  { class: "label",    x: 0, y: 5, width: 5,  height: 1, label: "Data to be applied:" }
			xPosition: { class: "checkbox", x: 0, y: 6, width: 1,  height: 1, config: true,  label: "&x",            value: true,  hint: "Apply x position data to the selected clips in the selected lines." }
			yPosition: { class: "checkbox", x: 1, y: 6, width: 1,  height: 1, config: true,  label: "&y",            value: true,  hint: "Apply y position data to the selected clips in the selected lines." }
			xScale:    { class: "checkbox", x: 0, y: 7, width: 2,  height: 1, config: true,  label: "&Scale",        value: true,  hint: "Apply scaling data to the selected clips in the selected lines." }
			zRotation: { class: "checkbox", x: 0, y: 8, width: 3,  height: 1, config: true,  label: "&Rotation",     value: false, hint: "Apply rotation data to the selected clips in the selected lines." }

			rectClip:  { class: "checkbox", x: 0, y: 10, width: 3,  height: 1, config: true, label: "Rect C&lip",    value: true,  hint: "Apply tracking data to the rectangular clip contained in the line." }
			vectClip:  { class: "checkbox", x: 3, y: 10, width: 3,  height: 1, config: true, label: "&Vect Clip",    value: true,  hint: "Apply tracking data to the vector clip contained in the line." }
			rcToVc:    { class: "checkbox", x: 6, y: 10, width: 4,  height: 1, config: true, label: "Rect -> Vect",  value: false, hint: "Convert rectangular clips contained in the line to vector clips." }

			startLabel:{ class: "label",    x: 7, y: 5, width: 3,  height: 1, label: "Start Frame:" }
			startFrame:{ class: "intedit",  x: 7, y: 6, width: 3,  height: 1, config: true,                          value: 1,     hint: "Frame used as the starting point for the tracking data. \"-1\" corresponds to the last frame." }
		}
		trim: {
			pLabel:   { class: "label", x: 0, y: 0, width: 10, height: 1, label: [[
Prefix the encoded video is written. Useful values are ?video for the
directory of the currently loaded video and ?script for the directory
of the currently open script. Can be a hardcoded path, too.]] }
			psLabel:  { class: "label", x: 0, y: 3, width: 10, height: 1, label: [[
Encoding preset. Different presets may have different output.]] }
			eLabel:   { class: "label", x: 0, y: 5, width: 10, height: 1, label: [[
The currently selected encoding binary. Use the "Encoder..." button
below to set this. Manual edits will not be saved.]] }
			cLabel:   { class: "label", x: 0, y: 7, width: 10, height: 1, label: [[
If you want to use a custom encoding command, write it here. Leave this
blank to use the built-in presets (probably what you want).]] }
			prefix:   { config: true, value: "?video", class: "textbox",  x: 0, y: 1, width: 10, height: 1,                                                             hint: "Prefix the encoded video is written. Useful values are ?video for the directory of the currently loaded video and ?script for the directory of the currently open script." }
			makePfix: { config: true, value: true,     class: "checkbox", x: 0, y: 2, width: 10, height: 1, label: "Try to create prefix directory.",                   hint: "Try to create prefix directory." }
			preset:   { config: true, value: "x264",   class: "dropdown", x: 0, y: 4, width: 10, height: 1, label: "Sort lines by", items: TrimHandler.existingPresets, hint: "Choose an existing preset by name." }
			encBin:   { config: true, value: "",       class: "textbox",  x: 0, y: 6, width: 10, height: 1,                                                             hint: "The full path to your encoding binary (x264.exe if you're using the default preset)" }
			command:  { config: true, value: "",       class: "textbox",  x: 0, y: 8, width: 10, height: 4,                                                             hint: "If you want to use a custom encoding command, write it here." }
		}
	}

	if TrimHandler.windows
		interface.trim.writeLog = { config: true, value: true, class: "checkbox", x: 0, y: 12, width: 10, height: 1, label: "Write encode log.", hint: "Write encode log. Allows aegisub-motion to print information if an encode fails. Only matters on Windows." }

	interface

fetchDataFromClipboard = ->
	-- According to vague reports, Aegisub clipboard usage crashes it on
	-- Linux. Disable any clipboard use until I find a better way to
	-- handle this.
	dataString = (jit.os != "Linux") and clipboard.get!

	-- If there's nothing on the clipboard, clipboard.get returns nil.
	return dataString or ""

prepareConfig = ( config, mainData, clipData, lineCollection ) ->
	rectClipData, vectClipData = nil, nil

	totalFrames = lineCollection.totalFrames

	for field, data in pairs { main: mainData, clip: clipData }
		configField = config[field]

		if '' == configField.data or nil == configField.data
			for option in pairs configField
				-- Nuke everything because it doesn't matter at this point.
				configField[option] = false

		else
			-- Be extremely lazy and just re-parse data from scratch.
			unless data\bestEffortParsingAttempt configField.data, lineCollection.meta.PlayResX, lineCollection.meta.PlayResY
				log.windowError "You put something in the #{field} data box\nbut it is wrong in ways I can't imagine."
			unless data.dataObject\checkLength totalFrames
				log.windowError "The length of your #{field} data (#{data.dataObject.length} frames) doesn't match\nthe length of your lines (#{totalFrames} frames) and I quit."

			if configField.rcToVc
				configField.rectClip = true
				configField.vectClip = true
			if configField.rectClip
				rectClipData = data
			if configField.vectClip
				vectClipData = data

	unless config.main.data or config.clip.data
		log.windowError "As far as I can tell, you've forgotten to give me any motion data."

	-- Disable options that depend on scale.
	unless config.main.xScale
		config.main.border = false
		config.main.shadow = false
		config.main.blur   = false

	-- Nudge the start frames.
	if config.main.relative
		for context in *{ 'main', 'clip' }
			-- Have to check that the field exists (if the clip dialog wasn't
			-- opened it will be nil) to avoid comparison with nil errors.
			if config[context].startFrame
				if config[context].startFrame == 0
					config[context].startFrame = 1
				elseif config[context].startFrame < 0
					config[context].startFrame = totalFrames + config[context].startFrame + 1
	else
		for context in *{ 'main', 'clip' }
			if config[context].startFrame
				config[context].startFrame = config[context].startFrame - lineCollection.startFrame + 1
				if config[context].startFrame <= 0
					log.windowError "You have specified an out-of-range absolute\nstart frame and you have been judged."

	return rectClipData, vectClipData

-- Used in getMissingTags, for fade handling when killTrans is used
getMissingAlphas = ( block, properties ) ->
	-- makes sure every necessary alpha tag exists in the first block
	alpha = Tags.allTags.alpha
	alpha1, alpha2, alpha3, alpha4 = Tags.allTags.alpha1, Tags.allTags.alpha2, Tags.allTags.alpha3, Tags.allTags.alpha4
	outline, shadow = Tags.allTags.border, Tags.allTags.shadow

	if block\find alpha.pattern
		return ''
	if ( properties[alpha1] == 0 and properties[alpha2] == 0 and
		 properties[alpha3] == 0 and properties[alpha4] == 0 )
		return alpha\format 0

	alphas = { }
	if not block\find alpha1.pattern
		table.insert alphas, alpha1\format properties[alpha1]
	if ( not block\find alpha2.pattern ) and ( block\find Tags.allTags.karaoke.pattern )
		table.insert alphas, alpha2\format properties[alpha2]
	if ( not block\find alpha3.pattern ) and ( ( block\find "\\[xy]?bord([%d%.]+)" ) or ( properties[outline] > 0 ) )
		table.insert alphas, alpha3\format properties[alpha3]
	if ( not block\find alpha4.pattern ) and ( ( block\find "\\[xy]?shad([%d%.]+)" ) or ( properties[shadow] > 0 ) )
		table.insert alphas, alpha4\format properties[alpha4]

	return table.concat alphas, ''

-- This table is used to verify that style defaults are inserted at
-- the beginning the selected line(s) if the corresponding options are
-- selected. The structure is: tag = { opt:"opt", skip:val } where
-- "opt" is the option that must be enabled and skip specifies
-- not to write the tag if the style default is that value.
importantTags = {
	xscale: { opt: "xScale", skip: 0 }
	yscale: { opt: "xScale", skip: 0 }
	border: { opt: "border", skip: 0 }
	shadow: { opt: "shadow", skip: 0 }
	zrot:   { opt: "zRotation" }
}
-- A style table is passed to this function so that it can cope with
-- \r.
getMissingTags = ( block, options, properties ) ->
	result = { }
	for key, tab in pairs importantTags
		tag = Tags.allTags[key]
		if options[tab.opt]
			if not block\match tag.pattern
				if properties[tag] != tab.skip
					table.insert result, tag\format properties[tag]
	if options.killTrans
		table.insert result, getMissingAlphas block, properties
	return table.concat result, ''

rectClipToVectClip = ( clip ) ->
	if clip\match "[%-%d%.]+, *[%-%d%.]+"
		clip = clip\gsub "([%-%d%.]+), *([%-%d%.]+), *([%-%d%.]+), *([%-%d%.]+)", ( l, t, r, b ) ->
			return table.concat ({
				"m %g %g "\format l, t
				"l %g %g "\format r, t
				"%g %g "\format r, b
				"%g %g"\format l, b
			})

	return clip

convertClipToFP = ( clip ) ->
	-- only muck around with vector clips (convert scaling factor into floating point coordinates).
	unless clip\match "[%-%d%.]+, *[%-%d%.]+"
		-- Convert clip with scale into floating point coordinates.
		clip = clip\gsub "%((%d*),?(.-)%)", ( scaleFactor, points ) ->
			if scaleFactor ~= ""
				scaleFactor = tonumber scaleFactor

				points = points\gsub "([%.%d%-]+) ([%.%d%-]+)", ( x, y ) ->
					x = Math.round tonumber( x )/(2^(scaleFactor - 1)), 2
					y = Math.round tonumber( y )/(2^(scaleFactor - 1)), 2

					("%g %g")\format x, y
			return '(' .. points .. ')'
	return clip

prepareLines = ( lineCollection ) ->
	setProgress 0

	totalLines = #lineCollection.lines

	options = lineCollection.options
	-- remove the lines while ensuring new lines will be inserted in the
	-- correct place.
	lineCollection\deleteLines!

	-- Perform all of the manipulation that used to be performed in
	-- Line.moon but are actually fairly Aegisub-Motion specific.
	lineCollection\runCallback ( line, index ) =>
		log.checkCancellation!
		-- If a line already contains a-mo extradata, it is probably being
		-- tracked again after being tracked. There are some reasons to do
		-- this, but it results in a huge amount of extradata garbage if
		-- unchecked. Presumably 99% of tracking that isn't this case will
		-- be on lines without extradata. This isn't a perfect solution, but
		-- it is probably better than before. This doesn't change
		-- extradata's lack of resilience toward copying lines between
		-- scripts.
		if line\getExtraData 'a-mo'
			line.retrack = true
		else
			-- Add our signature extradata.
			line\setExtraData 'a-mo', { originalText: line.text, uuid: Math.uuid! }

		-- Get default style properties (will be used later if transform
		-- interpolation is enabled)
		line\getPropertiesFromStyle!

		-- need to brutalize fades before tokenizing transforms so that the
		-- produced transforms will be tokenized as well. Alternately (this
		-- may be more clean but also less efficient), tokenize transforms,
		-- dedup tags, detokenize transforms, brutalize fades, and then
		-- retokenize transforms.
		line\tokenizeTransforms!

		line\runCallbackOnOverrides ( tagBlock ) =>
			return tagBlock\gsub "\\fade?%((%d+),(%d+)%)", ( start, finish ) ->
				return "\\fade(255,0,255,0,%d,%d,%d)"\format start, @duration - finish, @duration

		-- retokenize the transforms to simplify later processing.
		line\dontTouchTransforms!
		line\tokenizeTransforms!

		-- Deduplicate all override tags.
		line\deduplicateTags!

		-- Collect alignment and position info for each line.
		styles = @styles
		lineStyle = line.styleRef
		unless line\extraMetrics lineStyle
			-- unless line\moveToPosition math.floor(0.5*(aegisub.ms_from_frame(lineCollection.startFrame + options.main.startFrame - 1) + aegisub.ms_from_frame(lineCollection.startFrame + options.main.startFrame))) - line.start_time
			line\ensureLeadingOverrideBlockExists!

			-- Note that we are repeatedly shadowing @, so in this function it
			-- refers to the line. This is interestingly the opposite of how
			-- fat arrow functions work in coffeescript.
			line\runCallbackOnFirstOverride ( tagBlock ) =>
				return tagBlock\gsub "{", ("{\\pos(%g,%g)")\format @xPosition, @yPosition

		-- Add any tags we need that are missing from the line.
		line\runCallbackOnFirstOverride ( tagBlock ) =>
			tags = getMissingTags tagBlock, options.main, line.properties
			return '{' .. tags .. tagBlock\sub( 2 )

		line\runCallbackOnOverrides ( tagBlock ) =>
			tagBlock\gsub "\\org%([%.%d%-]+,[%.%d%-]+%)", ->
				@hasOrg = true
				return nil

			savestyle = line.styleRef
			reset = false
			tagBlock = tagBlock\gsub "\\r([^\\}]*)([^}]*)", ( resetStyle, remainder ) ->
				if styles[resetStyle]
					line.styleRef = styles[resetStyle]
					line\getPropertiesFromStyle!
					reset = true
				tags = getMissingTags remainder, options.main, line.properties
				return '\\r' .. resetStyle .. tags .. remainder
			if reset
				line.styleRef = savestyle
				line\getPropertiesFromStyle!

			if options.main.rectClip or options.main.vectClip or options.clip.rectClip or options.clip.vectClip
				tagBlock = tagBlock\gsub "(\\i?clip%b())", ( clip ) ->
					@hasClip = true
					clip = convertClipToFP clip
					if options.main.rcToVc or options.clip.rcToVc
						clip = rectClipToVectClip clip
					return clip

			return tagBlock

		unless line.hasClip
			line\runCallbackOnFirstOverride ( tagBlock ) =>
				"{\\clip()" .. tagBlock\sub 2

		setProgress index/totalLines*100

postprocLines = ( lineCollection ) ->
	setProgress 0

	totalLines = #lineCollection.lines

	lineCollection\runCallback ( line, index ) =>
		if line.wasLinear
			line\dontTouchTransforms!
		else
			line\deduplicateTags!

		line\shiftKaraoke!
		line.text = line.text\gsub "{}", ""

		setProgress index/totalLines*100
		log.checkCancellation!

	-- No progress for this.
	lineCollection\combineIdenticalLines!

applyProcessor = ( subtitles, selectedLines ) ->
	setTask     = aegisub.progress.task
	setProgress = aegisub.progress.set

	setTask "Loading Interface"
	initializeInterface!

	math.randomseed tonumber tostring( os.time! )\reverse!\sub( 1, 8 )

	-- Initialize the configuration
	options = ConfigHandler interface, "aegisub-motion.json", true, script_version
	options\read!
	options\updateInterface { "main", "clip" }

	stats = initStats!

	lineCollection = LineCollection subtitles, selectedLines

	currentVideoFrame = aegisub.project_properties!.video_position

	rawInputData = fetchDataFromClipboard!

	-- Instantiate both of these so they can be passed by reference later.
	setTask "Checking Clipboard for Data"
	mainData = DataWrapper!
	clipData = DataWrapper!
	if mainData\bestEffortParsingAttempt rawInputData, lineCollection.meta.PlayResX, lineCollection.meta.PlayResY
		if mainData.dataObject\checkLength lineCollection.totalFrames
			interface.main.data.value = rawInputData
			interface.main.dataLabel.label = "                Data is the correct length."
		else
			interface.main.dataLabel.label = "Data had the wrong framecount. Expected: #{lineCollection.totalFrames}. Got: #{mainData.dataObject.length}"

	if options.configuration.main.relative
		relativeFrame = currentVideoFrame - lineCollection.startFrame + 1
		if relativeFrame > 0 and relativeFrame <= lineCollection.totalFrames
			interface.main.startFrame.value = relativeFrame
			interface.clip.startFrame.value = relativeFrame
	else
		interface.main.startFrame.value = currentVideoFrame
		interface.clip.startFrame.value = currentVideoFrame

	setTask "Launching Interface"

	-- cancel:Abort in the main dialog tells Esc key to abort the entire macro
	-- cancel:Back in \clip dialog tells Esc key to close it and go back to the main dialog
	buttons = {
		main: {
			list: {
				"&Go"
				"Track &\\clip separately"
				"&Quit"
			}
			namedList: {
				ok: "&Go"
				clip: "Track &\\clip separately"
				cancel: "&Quit"
			}
		}
		clip: {
			list: {
				"&Go"
				"&Back"
				"&Quit"
			}
			namedList: {
				ok: "&Go"
				close: "&Back"
				abort: "&Quit"
			}
		}
	}

	currentDialog = "main"
	config = { clip: { }, main: { } }

	while true
		button, config[currentDialog] = aegisub.dialog.display interface[currentDialog], buttons[currentDialog].list, buttons[currentDialog].namedList

		for k, v in pairs config[currentDialog]
			interface[currentDialog][k].value = v

		switch button
			when buttons.main.namedList.clip
				currentDialog = "clip"

			when false, buttons.clip.namedList.abort
				setTask "ABORT"
				aegisub.cancel!

			when buttons.clip.namedList.close
				currentDialog = "main"

			else
				break

	-- Update the persistent configuration before it gets (potentially)
	-- horribly mutilated in prepareConfig. Ensures that what the user saw
	-- last is what will be presented to them next time.
	if config.main.writeConf
		setTask "Updating Configuration"
		options\updateConfiguration config, { "main", "clip" }
	if config.main.writeConf or (options.configuration.main.writeConf != config.main.writeConf)
		options.configuration.main.writeConf = config.main.writeConf
		options\write!

	setTask "Preparing Configuration and Data"
	rectClipData, vectClipData = prepareConfig config, mainData, clipData, lineCollection
	lineCollection.options = config

	setTask "Preprocessing Lines"
	prepareLines lineCollection
	stats\setMax "apply.longestTrack", lineCollection.totalFrames
	stats\setMax "apply.lines.largestInput", #lineCollection.lines
	for line in *lineCollection.lines
		stats\setMax "apply.bytes.largestInput", #line.text

	if mainData.type and 'SRS' != mainData.type
		mainData.dataObject\addReferenceFrame config.main.startFrame
		mainData.dataObject\stripFields config.main
	if clipData.type and 'SRS' != clipData.type
		clipData.dataObject\addReferenceFrame config.clip.startFrame
		clipData.dataObject\stripFields config.clip

	setTask "Applying Data"
	motionHandler = MotionHandler lineCollection, mainData, rectClipData, vectClipData
	newLines = motionHandler\applyMotion!

	-- Postproc lines: detokenize transforms and combine identical lines.
	setTask "Postprocessing Lines"
	postprocLines newLines
	newLines\replaceLines!

	stats\setMax "apply.lines.largestOutput", #newLines.lines
	stats\incrementValue "apply.lines.totalOutput", #newLines.lines
	for line in *newLines.lines
		stats\setMax "apply.bytes.largestOutput", #line.text
		stats\incrementValue "apply.bytes.totalOutput", #line.text
	stats\incrementValue "apply.runCount"
	stats\write!

trimConfigDialog = ( options ) ->
	buttons = {
		{ "&Save", "&Encoder...", "&Cancel" },
		{ ok: "&Save", enc: "&Encoder...", cancel: "&Cancel" }
	}
	while true
		options\updateInterface "trim"
		button, config = aegisub.dialog.display interface.trim, buttons[1], buttons[2]
		if button == buttons[2].ok or button == buttons[2].enc
			-- only update encBin when the open dialog is shown.
			config.encBin = nil
			options\updateConfiguration config, "trim"
			if button == buttons[2].ok
				options\write!
				break
			else
				encoder = aegisub.dialog.open "Choose an Encoding Binary", "", "", "", false, true
				if encoder
					options\updateConfiguration { encBin: encoder }, "trim"
		else
			aegisub.cancel!

trimConfigurator = ->
	initializeInterface!
	options = ConfigHandler interface, "aegisub-motion.json", true, script_version
	options\read!
	trimConfigDialog options

trimProcessor = ( subtitles, selectedLines, activeLine, eachFlag ) ->
	setTask     = aegisub.progress.task
	setProgress = aegisub.progress.set

	initializeInterface!
	options = ConfigHandler interface, "aegisub-motion.json", true, script_version

	stats = initStats!
	options\read!

	-- Check if encBin has been set.
	if options.configuration.trim.encBin == ""
		interface.trim.pLabel.label = [[
You must specify the path to your encoding binary.

]] .. interface.trim.pLabel.label
		trimConfigDialog options

	trim = TrimHandler options.configuration.trim
	if eachFlag
		seenRanges = { }
		for lineIndex in *selectedLines
			lineCollection = LineCollection subtitles, { lineIndex }
			collectionRange = "#{lineCollection.startFrame}-#{lineCollection.endFrame}"
			unless seenRanges[collectionRange]
				seenRanges[collectionRange] = true
				trim\calculateTrimLength lineCollection
				trim\performTrim!
				stats\incrementValue "trim.clipsCreated"
		stats\incrementValue "trimEach.runCount"

	else
		lineCollection = LineCollection subtitles, selectedLines
		trim\calculateTrimLength lineCollection
		trim\performTrim!
		stats\incrementValue "trim.clipsCreated"
		stats\incrementValue "trim.runCount"

	stats\write!
	return selectedLines

trimProcessorEach = ( subtitles, selectedLines ) ->
	trimProcessor subtitles, selectedLines, nil, true

revertProcessor = ( subtitles, selectedLines ) ->
	setTask     = aegisub.progress.task
	setProgress = aegisub.progress.set
	stats = initStats!

	setTask "Collecting UUIDs"
	-- A table of all UUIDs found in the selected lines
	uuids = { }
	-- Indices of lines that need to be removed later (are part of a
	-- tracked line collection, but are not the first line in that
	-- collection)
	for index in *selectedLines
		with line = subtitles[index]
			if .extra['a-mo']
				data = json.decode .extra['a-mo']
				unless uuids[data.uuid]
					.text = data.originalText
					.number = index
					.extra = {}
					uuids[data.uuid] = line

	indicesToNuke = { }

	setTask "Gathering Matching Lines"
	totalLines = #subtitles

	for index = 1, totalLines
		with line = subtitles[index]
			if line.extra
				-- Catch lines containing our signature extradata.
				if .extra['a-mo']
					-- Decode our data, which is stored as json.
					data = json.decode .extra['a-mo']
					if uuids[data.uuid]
						oldLine = uuids[data.uuid]
						-- Check if we should change the start time.
						if .start_time < oldLine.start_time
							oldLine.start_time = .start_time
						-- Check if we should change the end time.
						if .end_time > oldLine.end_time
							oldLine.end_time = .end_time
						-- Mark the line for deletion.
						if index < oldLine.number
							oldLine.number = index
						elseif index > oldLine.number
							stats\incrementValue "revert.bytes.total", #line.text
							indicesToNuke[#indicesToNuke+1] = index

		setProgress index/totalLines*100

	setTask "Replacing Lines"
	-- Replace the lines.
	for _, line in pairs uuids
		subtitles[line.number] = line

	-- Delete the remainders.
	subtitles.delete indicesToNuke
	stats\incrementValue "revert.lines.total", #indicesToNuke

	stats\incrementValue "revert.runCount"
	stats\write!
	return nil

canRun = ( sub, selectedLines ) ->
	if not aegisub.frame_from_ms 0
		return false, "You must have a video loaded to run this macro."
	elseif 0 == #selectedLines
		return false, "You must have lines selected to use this macro."
	true

if haveDepCtrl
	versionRecord\registerMacros {
		{ "Apply", "Applies properly formatted motion tracking data to selected subtitles.", applyProcessor, canRun }
		{ "Revert", "Removes properly formatted motion tracking data from selected subtitles.", revertProcessor }
		{ "Trim", "Cuts and encodes the current scene for use with motion tracking software.", trimProcessor, canRun }
		{ "Trim Each", "Cuts and encodes selected scenes for use with motion tracking software.", trimProcessorEach, canRun }
		{ "Trim Settings", "Opens a gui to configure the trim tool.", trimConfigurator }
	}
else
	aegisub.register_macro "#{script_name}/Apply", "Applies properly formatted motion tracking data to selected subtitles.",
		applyProcessor, canRun

	aegisub.register_macro "#{script_name}/Revert", "Removes properly formatted motion tracking data from selected subtitles.",
		revertProcessor

	aegisub.register_macro "#{script_name}/Trim", "Cuts and encodes the current scene for use with motion tracking software.",
		trimProcessor, canRun

	aegisub.register_macro "#{script_name}/Trim Each", "Cuts and encodes selected scenes for use with motion tracking software.",
		trimProcessorEach, canRun

	aegisub.register_macro "#{script_name}/Trim Settings", "Opens a gui to configure the trim tool.",
		trimConfigurator
