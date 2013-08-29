-- tophf is a pretty cool guy and ported this to moonscript for me. So thank him.
-- Maybe one day I will make it better (hahahahahaha yeah right).


-- I THOUGHT I SHOULD PROBABLY INCLUDE SOME LICENSING INFORMATION IN THIS
-- BUT I DON'T REALLY KNOW VERY MUCH ABOUT COPYRIGHT LAW AND IT ALSO SEEMS LIKE MOST
-- COPYRIGHT NOTICES JUST KIND OF YELL AT YOU IN ALL CAPS. AND APPARENTLY PUBLIC
-- DOMAIN DOES NOT EXIST IN ALL COUNTRIES, SO I FIGURED I'D STICK THIS HERE SO
-- YOU KNOW THAT YOU, HENCEFORTH REFERRED TO AS "THE USER" HAVE THE FOLLOWING
-- INALIABLE RIGHTS:

--   0. THE USER should realize that starting a list with 0 in a document that contains
--     lua code is actually SOMEWHAT IRONIC.
--   1. THE USER can use this piece of poorly written code, henceforth referred to as
--     THE SCRIPT, to do the things that it claims it can do.
--   2. THE USER should not expect THE SCRIPT to do things that it does not expressly
--     claim to be able to do, such as make coffee or print money.
--   3. THE WRITER, henceforth referred to as I or ME, depending on the context, holds
--     no responsibility for any problems that THE SCRIPT may cause, such as if it
--     murders your dog.
--   4. THE USER is expected to understand that this is just some garbage that I made
--     up and that any and all LEGALLY BINDING AGREEMENTS THAT THE USER HAS AGREED
--     TO UPON USAGE OF THE SCRIPT ARE UP TO THE USER TO DISCOVER ON HIS OR HER OWN,
--     POSSIBLY THROUGH CLAIRVOYANCE OR MAYBE A SPIRITUAL MEDIUM.
--   5. For fear of someone else attempting to steal my INTELLECTUAL PROPERTY, which
--     is the result of MY OWN PERSONAL EFFORT and has come at the consequence of the
--     EVAPORATION of ALL OF MY FREE TIME, I have decided to make ARBITRARY PARTS of
--     this script PROPRIETARY CODE that THE USER IS ABSOLUTELY AND EXPLICITLY VERBOTEN
--     FROM LOOKING AT AT ANY TIME.
--   6. This LICENSE AGREEMENT, which is IMPLICITLY AGREED TO upon usage of the script,
--     regardless of whether or not THE USER has actually read it, IS RETROACTIVELY
--     EXTENSIBLE. This means that ANY SUBSEQUENT TERMS ADDED TO IT IMMEDIATELY APPLY
--     TO ALL OF THE USER'S ACTIONS IN THE PAST, and THE USER should be VERY CAREFUL
--     that they have not previously VIOLATED any FUTURE TERMS AND CONDITIONS lest they
--     be legally OPPRESSED by ME in a COURT OF LAW.
--   7. Should THE SCRIPT turn out to secretly be a cleverly disguised COMPUTER VIRUS in
--     disguise, THE USER has agreed that any or all information it has gathered hereby
--     belongs to ME and I CLAIM FULL RIGHTS TO IT, INCLUDING THE RIGHT TO REDISTRIBUTE
--     IT AS I SEE FIT. THE USER also agrees to make NO PREVENTATIVE MEASURES to keep
--     HIS OR HER computer from becoming PART OF THE BOTNET HIVEMIND. FURTHERMORE, THE
--     USER agrees to take FULL PERSONAL RESPONSIBILITY for ANY ILLEGAL ACTIVITIES that
--     HIS OR HER computer partakes in while under the CONTROL OF THE BOTNET.
--   8. This is an IMPORTANT NOTIFICATION, you should try to defraud SOME STUPID WIG
--     posing as THE AUTHOR OF THIS SOFTWARE, you will be hunted down to a REASONABLE
--     RABIES WOLF, in a timely manner to THE MURDER OF YOUR PACKAGE, and then eat YOUR
--     BODY. There will be ANY OF THE AUTHORITIES to find you the possibility of leaving
--     are VERY SLIM, even IN THE UNLIKELY EVENT THIS DOES OCCUR, will have to cope with
--     the MURDER. In addition, I HAPPEN TO HAVE an independent country, DO NOT CARE
--     ABOUT THE LITTLE THINGS, such as THE MURDER OF A BEAUTIFUL APARTMENT. Besides, I
--     have MY LAWYER to prosecute THE GOOD NAME OF YOUR DISTRAUGHT FAMILY, you have a
--     stain, so I CHANGE FROM THIRD PERSON TO FIRST PERSON HARM, but I think this
--     subtlety will be lost to Google Translate. In short, FUCK YOU.
--   9. THE USER understands that while the inclusion of a CHINESE MOONRUNE CLAUSE in
--     the LICENSE AGREEMENT was VITALLY IMPORTANT, it unfortunately HAD TO BE REMOVED
--     because THE LUA PARSER IS EVER SO FRAGILE and has been known to do VERY CONFUSING
--     THINGS in the face of MULTIBYTE CHARACTERS, even when THE SCRIPT is encoded as
--     UTF-8. A HIGH QUALITY translation of the PREVIOUS TERM HAS BEEN SUBSTITUTED IN
--     for the FORESEEABLE FUTURE. Should it raise ANY QUESTIONS, THE USER is welcome to
--     JUST GO AHEAD AND JUMP OFF OF A BRIDGE because his or her stupidity is OBVIOUSLY
--     INCURABLE.
--  10. THE USER must understand the difference between a COPYRIGHT LICENSE and an END-USER
--     LICENSE AGREEMENT. COPYRIGHT LICENSES are THE THINGS that get put ON TOP of A PIECE
--     OF CODE that tell people that YOU ARE NOT LEGALLY ALLOWED TO REDISTRIBUTE THIS FILE
--     UNLESS YOU HAVE RECENTLY CASTRATED YOURSELF WITH A SPORK and even then only under
--     SPECIFIC CIRCUMSTANCES. END-USER LICENSE AGREEMENTS are THE UNREADABLE WALLS OF
--     LEGALESE that HUMONGOUS, PROFITABLE CORPORATIONS pay LEGIONS OF LEGAL PERSONELLE to
--     develop that tell you that YOU ARE NOT LEGALLY ALLOWED TO USE THE SOFTWARE YOU JUST
--     INSTALLED UNLESS YOU WILLINGLY CONSIGN YOUR ENTIRE ESTATE TO SAID CORPORATION IN
--     YOUR LAST WILL AND TESTAMENT.


export script_name        = "Aegisub-Motion"
export script_description = "A set of tools for simplifying the process of creating and applying motion tracking data with Aegisub."
export script_author      = "torque"
export script_version     = "0.5.0"

config_file = "aegisub-motion.conf"

local *
local gui, guiconf, winpaths, encpre, global, alltags, globaltags, importanttags

require "karaskel"
require "clipboard"
success, re = pcall require, "aegisub.re"
re = require "re" unless success

onetime_init = ->
	return if gui

	-- [[ Detect whether to use *nix or Windows style paths. ]]--
	winpaths = not aegisub.decode_path('?data')\match('/')

	-- [[ Set up interface tables. ]]--
	gui = {
		main: {
			-- mnemonics: xyOCSBuRWen + G\A + Wl\A
			linespath: {"textbox",  0, 1,  10, 4, name:  "linespath", hint: "Paste data or the path to a file containing it. No quotes or escapes."}
			pref:      {"textbox",  0, 14, 10, 3, name:  "pref", hint: "The prefix", hint: "The directory any generated files will be written to."}
			preflabel: {"label",    0, 13, 10, 1, label: "                  Files will be written to this directory."}
			datalabel: {"label",    0, 0,  10, 1, label: "                       Paste data or enter a filepath."}
			optlabel:  {"label",    0, 6,  5,  1, label: "Data to be applied:"}
			rndlabel:  {"label",    7, 6,  3,  1, label: "Rounding"}
			xpos:      {"checkbox", 0, 7,  1,  1, name:  "xpos", value: true, label: "&x", hint: "Apply x position data to the selected lines."}
			ypos:      {"checkbox", 1, 7,  1,  1, name:  "ypos", value: true, label: "&y", hint: "Apply y position data to the selected lines."}
			origin:    {"checkbox", 2, 7,  2,  1, name:  "origin", value: false, label: "&Origin", hint: "Move the origin along with the position."}
			clip:      {"checkbox", 4, 7,  2,  1, name:  "clip", value: false, label: "&Clip", hint: "Move clip along with the position (note: will also be scaled and rotated if those options are selected)."}
			scale:     {"checkbox", 0, 8,  2,  1, name:  "scale", value: true, label: "&Scale", hint: "Apply scaling data to the selected lines."}
			border:    {"checkbox", 2, 8,  2,  1, name:  "border", value: true, label: "&Border", hint: "Scale border with the line (only if Scale is also selected)."}
			shadow:    {"checkbox", 4, 8,  2,  1, name:  "shadow", value: true, label: "&Shadow", hint: "Scale shadow with the line (only if Scale is also selected)."}
			blur:      {"checkbox", 4, 9,  2,  1, name:  "blur", value: true, label: "Bl&ur", hint: "Scale blur with the line (only if Scale is also selected, does not scale \\be)."}
			rotation:  {"checkbox", 0, 9,  3,  1, name:  "rotation", value: false, label: "&Rotation", hint: "Apply rotation data to the selected lines."}
			posround:  {"intedit",  7, 7,  3,  1, name:  "posround", value: 2, min: 0, max: 5, hint: "How many decimal places of accuracy the resulting positions should have."}
			sclround:  {"intedit",  7, 8,  3,  1, name:  "sclround", value: 2, min: 0, max: 5, hint: "How many decimal places of accuracy the resulting scales should have (also applied to border, shadow, and blur)."}
			rotround:  {"intedit",  7, 9,  3,  1, name:  "rotround", value: 2, min: 0, max: 5, hint: "How many decimal places of accuracy the resulting rotations should have."}
			wconfig:   {"checkbox", 0, 11, 4,  1, name:  "wconfig", value: false, label: "&Write config", hint: "Write current settings to the configuration file."}
			relative:  {"checkbox", 4, 11, 3,  1, name:  "relative", value: true, label: "R&elative", hint: "Start frame should be relative to the line's start time rather than to the start time of all selected lines"}
			stframe:   {"intedit",  7, 11, 3,  1, name:  "stframe", value: 1, hint: "Frame used as the starting point for the tracking data. \"-1\" corresponds to the last frame."}
			linear:    {"checkbox", 4, 12, 2,  1, name:  "linear", value: false, label: "Li&near", hint: "Use transforms and \\move to create a linear transition, instead of frame-by-frame."}
			sortd:     {"dropdown", 5, 5,  4,  1, name:  "sortd", hint: "Sort lines by", value: "Default", items: {"Default", "Time"}, hint: "The order to sort the lines after they have been tracked."}
			sortlabel: {"label",    1, 5,  4,  1, name:  "sortlabel", label: "      Sort Method:"}
		}
		clip: {
			-- mnemonics: xySRe + GCA
			clippath: {"textbox",   0, 1, 10, 4,  name:  "clippath", hint: "Paste data or the path to a file containing it. No quotes or escapes."}
			label:    {"label",     0, 0, 10, 1,  label: "                 Paste data or enter a filepath."}
			xpos:     {"checkbox",  0, 6, 1,  1,  name:  "xpos", value: true, label: "&x", hint: "Apply x position data to the selected lines."}
			ypos:     {"checkbox",  1, 6, 1,  1,  name:  "ypos", value: true, label: "&y", hint: "Apply y position data to the selected lines."}
			scale:    {"checkbox",  0, 7, 2,  1,  name:  "scale", value: true, label: "&Scale"}
			rotation: {"checkbox",  0, 8, 3,  1,  name:  "rotation", value: false, label: "&Rotation"}
			relative: {"checkbox",  4, 6, 3,  1,  name:  "relative", value: true, label: "R&elative"}
			stframe:  {"intedit",   7, 6, 3,  1,  name:  "stframe", value: 1}
		}
		t: {
			vidlabel: {"label",     0,  0, 30, 1, label: "The path to the loaded video"}
			input:    {"textbox",   0,  1, 30, 1, name:  "input"}
			idxlabel: {"label",     0,  2, 30, 1, label: "The path to the index file."}
			index:    {"textbox",   0,  3, 30, 1, name:  "index"}
			sflabel:  {"label",     0,  4, 15, 1, label: "Start frame"}
			startf:   {"intedit",   0,  5, 15, 1, name:  "startf"}
			eflabel:  {"label",     15, 4, 15, 1, label: "End frame"}
			endf:     {"intedit",   15, 5, 15, 1, name:  "endf"}
			oplabel:  {"label",     0,  6, 30, 1, label: "Video file to be written"}
			output:   {"textbox",   0,  7, 30, 1, name:  "output"}
		}
	}

	for _, dlg in pairs gui do conformdialog dlg

	-- [[ Set up encoder presets. ]]--
	encpre = {
		x264:    '"#{encbin}" --crf 16 --tune fastdecode -i 250 --fps 23.976 --sar 1:1 --index "#{prefix}#{index}.index" --seek #{startf} --frames #{lenf} -o "#{prefix}#{output}[#{startf}-#{endf}].mp4" "#{inpath}#{input}"'
		ffmpeg:  '"#{encbin}" -ss #{startt} -t #{lent} -sn -i "#{inpath}#{input}" "#{prefix}#{output}[#{startf}-#{endf}]-%%05d.jpg"'
		avs2yuv: 'echo FFVideoSource("#{inpath}#{input}",cachefile="#{prefix}#{index}.index").trim(#{startf},#{endf}).ConvertToRGB.ImageWriter("#{prefix}#{output}-[#{startf}-#{endf}]\\",type="png").ConvertToYV12 > "#{prefix}encode.avs"#{nl}mkdir "#{prefix}#{output}-[#{startf}-#{endf}]"#{nl}"#{encbin}" -o NUL "#{prefix}encode.avs"#{nl}del "#{prefix}encode.avs"'
		-- vapoursynth =
	}

	-- [[ Set up a table of global options. Defaults included. ]]--
	with global = {
			prefix:   "?video"
			encoder:  "x264" -- todo: move to trim options
			encbin:   ""     -- same
			gui_trim: false  -- same
			autocopy: true
			acfilter: true
			delsourc: false
		}
		-- [[ Set encoding command default based on preset. ]]--
		.enccom = encpre[.encoder] or ""

	-- [[ Copy the main GUI with some modifications for the config GUI. Helps to lower the amount of code duplication (???) ]]--
	gui.conf = table.copy_deep gui.main
	with gui.conf
		.clippath, .linespath, .wconfig = nil
		.encbin, .pref = table.copy(.pref), nil
		.encbin.value, .encbin.name = global.encbin, "encbin"
		.encbin.hint = "The full path to the encoder binary (unless it's in your PATH)"
		.datalabel.label = "       Enter the path to your prefix here (include trailing slash)."
		.preflabel.label = "First box: path to encoder binary; second box: encoder command."

	for k, e in pairs conformdialog {
			gui_trim: {"checkbox", 3, 22, 4, 1, value: global.trim, label: "Enable trim GUI", name: "gui_trim", hint: "Set whether or not the trim gui should appear."}
			enccom:   {"textbox",  0, 17, 10, 4, value: global.enccom,                         name: "enccom",   hint: "The encoding command that will be used. If you change this, set the preset to \"custom\"."}
			prefix:   {"textbox",  0, 1, 10, 4, value: global.prefix,                         name: "prefix",   hint: "The folder to which all generated files will be written."}
			encoder:  {"dropdown", 0, 11, 2, 1, value: global.encoder,                        name: "encoder",
			                                 items: {"x264", "ffmpeg", "avs2yuv", "custom"},                 hint: "Choose one of the encoding command presets (set to custom if you have made any modifications to the defaults)"}
			delsourc: {"checkbox", 0, 21, 2, 1, value: global.delsourc, label: "Delete",      name: "delsourc", hint: "Delete the source lines instead of commenting them out."}
			autocopy: {"checkbox", 3, 21, 3, 1, value: global.autocopy, label: "Autocopy",    name: "autocopy", hint: "Automatically copy the contents of the clipboard into the tracking data box on script run."}
			acfilter: {"checkbox", 7, 21, 3, 1, value: global.acfilter, label: "Copy Filter", name: "acfilter", hint: "Only automatically copy the clipboard if it appears to contain tracking data."}
		}
		gui.conf[k] = e

	-- [[ A table of all override tags that can be looped through. For detecting dupes in cleanup. ]]--
	alltags = {
		xscl:  [[\fscx([%d%.]+)]]
		yscl:  [[\fscy([%d%.]+)]]
		ali:   [[\an([1-9])]]
		zrot:  [[\frz?([%-%d%.]+)]]
		bord:  [[\bord([%d%.]+)]]
		xbord: [[\xbord([%d%.]+)]]
		ybord: [[\ybord([%d%.]+)]]
		shad:  [[\shad([%-%d%.]+)]]
		xshad: [[\xshad([%-%d%.]+)]]
		yshad: [[\yshad([%-%d%.]+)]]
		reset: [[\r([^\\}]*)]]
		alpha: [[\alpha&H(%x%x)&]]
		l1a:   [[\1a&H(%x%x)&]]
		l2a:   [[\2a&H(%x%x)&]]
		l3a:   [[\3a&H(%x%x)&]]
		l4a:   [[\4a&H(%x%x)&]]
		l1c:   [[\c&H(%x+)&]]
		l1c2:  [[\1c&H(%x+)&]]
		l2c:   [[\2c&H(%x+)&]]
		l3c:   [[\3c&H(%x+)&]]
		l4c:   [[\4c&H(%x+)&]]
		clip:  [[\clip%((.-)%)]]
		iclip: [[\iclip%((.-)%)]]
		be:    [[\be([%d%.]+)]]
		blur:  [[\blur([%d%.]+)]]
		fax:   [[\fax([%-%d%.]+)]]
		fay:   [[\fay([%-%d%.]+)]]
	}

	globaltags = {
		fad:  "\\fad%([%d]+,[%d]+%)"
		fade: "\\fade%(([%d]+),([%d]+),([%d]+),([%-%d]+),([%-%d]+),([%-%d]+),([%-%d]+)%)"
		clip: ""
	}

	-- This is a rather messy table of tags that is used to verify that
	-- style defaults are inserted at the beginning the selected line(s)
	-- if the corresponding options are selected. The structure is:
	-- [tag] = {{"opt1","opt2"}, "style key", don't write}
	-- where "opt1" and "opt2" are the options that both must be true,
	-- "style key" is the key to get the style value, and
	-- don't write specifies not to write the tag if the style default is that value.
	importanttags = {
		['\\fscx']: {opt:{a:"scale",   b:"scale"},    key:"scale_x", skip:0}
		['\\fscy']: {opt:{a:"scale",   b:"scale"},    key:"scale_y", skip:0}
		['\\bord']: {opt:{a:"border",  b:"scale"},    key:"outline", skip:0}
		['\\shad']: {opt:{a:"shadow",  b:"scale"},    key:"shadow",  skip:0}
		['\\frz']:  {opt:{a:"rotation", b:"rotation"}, key:"angle"}
	}

	-- A table of config keys whose values should be written to the
	-- configurtion file. structure is [header] = {keys...} ]]--
	guiconf = {
		main: {
			"sortd",
			"xpos", "ypos", "origin", "clip", "posround",
			"scale", "border", "shadow", "blur", "sclround",
			"rotation", "rotround",
			"relative", "stframe",
			"linear", --"export",
		}
		clip: {
			"xpos", "ypos", "scale", "rotation",
			"relative", "stframe",
		}
	}

	-- [[ Stick the global config keys in the above table. ]]--
	for k, v in pairs global
		table.insert guiconf, k

-------------------------------------------------------------------------------

init_input = (sub, sel) -> -- THIS IS PROPRIETARY CODE YOU CANNOT LOOK AT IT

	onetime_init!

	setundo = aegisub.set_undo_point -- ugly workaround for a problem that was causing random crashes
	printmem "GUI startup"

	conf, accd = dialogPreproc sub, sel

	-- cancel:Abort in the main dialog tells Esc key to abort the entire macro
	-- cancel:Cancel in \clip dialog tells Esc key to close it and go back to the main dialog
	btns = {
			main: makebuttons {{ok:"&Go"}, {clip:"&\\clip..."}, {cancel:"&Abort"}}
			clip: makebuttons {{ok:"&Go clippin'"}, {cancel:"&Cancel"}, {abort:"&Abort"}}
		}
	dlg = "main"

	while true
		local clipconf, button, config

		with btns[dlg]
			button, config = aegisub.dialog.display(gui[dlg], .__list, .__namedlist)

		switch button
			when btns.main.clip
				dlg = "clip"
				continue

			when btns.main.ok, btns.clip.ok
				clipconf = clipconf or {} -- solve indexing errors
				for field in *guiconf.clip
					if clipconf[field] == nil then clipconf[field] = gui.clip[field].value
				config.linespath = false if config.linespath == ""

				writeconf conf, {main: config, clip: clipconf, global: global} if config.wconfig

				config.stframe   = 1 if config.stframe == 0 -- TODO: fix this horrible clusterfuck
				clipconf.stframe = 1 if clipconf.stframe == 0

				config.position   = true if config.xpos or config.ypos
				clipconf.position = true if clipconf.xpos or clipconf.ypos

				config.yconst   = not config.ypos
				config.xconst   = not config.xpos
				clipconf.yconst = not clipconf.ypos
				clipconf.xconst = not clipconf.xpos -- TODO: remove unnecessary logic inversion

				clipconf.stframe = config.stframe if config.clip
				config.linear    = false if config.clip or clipconf.clippath

				if clipconf.clippath == "" or clipconf.clippath == nil
					if not config.linespath then windowerr false, "No tracking data was provided."
					clipconf.clippath = false
				else
					config.clip = false -- set clip to false if clippath exists

				aegisub.progress.title "Mincing Gerbils"
				printmem "Go"

				newsel = frame_by_frame sub, accd, config, clipconf
				if munch sub, newsel
					newsel = {}
					for x = 1, #sub
						table.insert newsel, x if tostring(sub[x].effect)\match("^aa%-mou")

				aegisub.progress.title "Reformatting Gerbils"
				cleanup sub, newsel, config
				break

			else
				if dlg == 'main' or button == btns.clip.abort
					aegisub.progress.task "ABORT"
					aegisub.cancel!
				else
					dlg = "main"
					continue

	setundo "Motion Data"
	printmem "Closing"

-------------------------------------------------------------------------------

parse_input = (mocha_table, input, shx, shy) ->

	printmem "Start of input parsing"
	sect, care = 0, 0
	ftab, mocha_table.xpos, mocha_table.ypos, mocha_table.xscl, mocha_table.yscl, mocha_table.zrot = {}, {}, {}, {}, {}, {}

	datams = io.open input, "r" -- a terrible idea? Doesn't seem to be so far.
	datastring = ""
	if datams
		for line in datams\lines()
			line = line\gsub "[\r\n]*", "" -- FUCK YOU CRLF
			datastring ..= line.."\n"
			table.insert ftab, line -- dump the lines from the file into a table.
		datams\close()
	else
		input = input\gsub "[\r]*", "" -- SERIOUSLY FUCK THIS SHIT
		datastring = input
		ftab = input\split("\n")

	for pattern in *{"Position", "Scale", "Rotation", "Source Width\t%d+", "Source Height\t%d+", "Adobe After Effects 6.0 Keyframe Data"}
		windowerr datastring\match(pattern), 'Error parsing data. "After Effects Transform Data [anchor point, position, scale and rotation]" expected.'

	xmult = shx/tonumber(datastring\match "Source Width\t([0-9]+)")
	ymult = shy/tonumber(datastring\match "Source Height\t([0-9]+)")

	with mocha_table
		for keys, valu in ipairs ftab -- idk it might be more flexible now or something
			if not valu\match("^\t")
				switch valu
					when "Position" then sect = 1
					when "Scale" then sect += 2
					when "Rotation" then sect += 4
			else
				val = valu\split "\t"
				switch sect
					when 1
						if valu\match("%d")
							table.insert .xpos, tonumber(val[2])*xmult
							table.insert .ypos, tonumber(val[3])*ymult
					when 3
						if valu\match("%d")
							table.insert .xscl, tonumber(val[2])
							table.insert .yscl, tonumber(val[3])
					when 7
						if valu\match("%d")
							table.insert .zrot, -tonumber(val[2])
		.flength = #.xpos
		for x in *{#.ypos, #.xscl, #.yscl, #.zrot}
			windowerr x == .flength, 'Error parsing data. "After Effects Transform Data [anchor point, position, scale and rotation]" expected.'

	for prefix, field in pairs {x: "xpos", y: "ypos", xs: "xscl", ys: "yscl", r: "zrot"}
		dummytab = table.copy mocha_table[field]
		table.sort dummytab
		mocha_table[prefix.."min"] = dummytab[1]
		mocha_table[prefix.."max"] = dummytab[#dummytab]
		debug "%smax: %g; %smin: %g", prefix, mocha_table[prefix.."max"], prefix, mocha_table[prefix.."min"]

	printmem "End of input parsing"

-------------------------------------------------------------------------------

populateInputBox = ->

	if global.autocopy
		paste = clipboard.get() or "" -- if there's nothing on the clipboard, clipboard.get retuns nil
		if global.acfilter
			if paste\match("^Adobe After Effects 6.0 Keyframe Data")
				gui.main.linespath.value = paste
		else
			gui.main.linespath.value = paste

-------------------------------------------------------------------------------

dialogPreproc = (sub, sel) ->

	aegisub.progress.title "Selecting Gerbils"
	accd = getSelInfo sub, sel
	for f in *{gui.main.stframe, gui.clip.stframe}
		f.min = -accd.totframes
		f.max =  accd.totframes

	local conf -- the scope of assignment in conditionals is limited to that conditional by default.
	if conf = configscope()
		if not readconf conf, {main: gui.main, clip: gui.clip, global: global}
			warn "Failed to read config!"

	populateInputBox!

	gui.main.pref.value = aegisub.decode_path global.prefix
	return conf, accd

-------------------------------------------------------------------------------

getSelInfo = (sub, sel) ->

	printmem "Initial"
	local strt

	for x = 1, #sub
		if sub[x].class == "dialogue"
			strt = x - 1 -- start line of dialogue subs
			break

	aegisub.progress.title "Collecting Gerbils"
	_ = nil
	accd = {}
	accd.meta, accd.styles = karaskel.collect_head(sub, false) -- dump everything I need later into the table so I don't have to pass o9k variables to the other functions
	accd.lines = {}
	accd.endframe = aegisub.frame_from_ms sub[sel[1]].end_time -- get the end frame of the first selected line
	accd.startframe = aegisub.frame_from_ms sub[sel[1]].start_time -- get the start frame of the first selected line

	numlines = #sel
	for i = #sel, 1, -1
		with line = sub[sel[i]] -- CHK
			.num = sel[i] -- for inserting lines later
			.hnum = .num - strt -- humanized number

			karaskel.preproc_line sub, accd.meta, accd.styles, line -- get linewidth/height and margins
			.effect = "" if not .effect
			sub[sel[i]] = extraLineMetrics line

			.startframe = aegisub.frame_from_ms .start_time
			.endframe   = aegisub.frame_from_ms .end_time
			.is_comment = .comment == true

			if .startframe < accd.startframe -- make timings flexible. Number of frames total has to match the tracked data but
				debug "Line %d: startframe changed from %d to %d", .num - strt, accd.startframe, .startframe
				accd.startframe = .startframe

			if .endframe > accd.endframe -- individual lines can be shorter than the whole scene
				debug "Line %d: endframe changed from %d to %d", .num - strt, accd.endframe, .endframe
				accd.endframe = .endframe

			if .endframe - .startframe > 1
				table.insert accd.lines, line

	accd.totframes = accd.endframe - accd.startframe
	assert #accd.lines > 0, "You have to select at least one line that is longer than one frame long." -- pro error checking
	printmem "End of preproc loop"
	return accd

-------------------------------------------------------------------------------

spoof_table = (parsed_table, opts, len) ->

	with parsed_table
		len = len or #.xpos
		.xpos = .xpos or {}
		.ypos = .ypos or {}
		.xscl = .xscl or {}
		.yscl = .yscl or {}
		.zrot = .zrot or {}

		if not opts.position
			for k = 1, len do .xpos[k], .ypos[k] = 0, 0
		else
			if opts.yconst then for k = 1, len do .ypos[k] = 0
			if opts.xconst then for k = 1, len do .xpos[k] = 0

		if not opts.scale then for k = 1, len do .xscl[k], .yscl[k] = 100, 100
		if not opts.rotation then for k = 1, len do .zrot[k] = 0

		.s = 1
		.s = .flength if opts.reverse

-------------------------------------------------------------------------------

extraLineMetrics = (line) ->

	line.trans = {}
	fstart, fend = line.text\match "\\fad%((%d+),(%d+)%)" -- only uses the first one
	line.text = line.text\gsub globaltags.fad, "" -- kill them all

	lextrans = (trans) ->
		t_start, t_end, t_exp, t_eff = trans\sub(2, -2)\match "([%-%d]+),([%-%d]+),([%d%.]*),?(.+)"
		t_exp = tonumber(t_exp) or 1 -- set to 1 if unspecified
		table.insert line.trans, {tonumber(t_start), tonumber(t_end), t_exp, t_eff}
		debug "Line %d: \\t(%g,%g,%g,%s) found", line.hnum, t_start, t_end, t_exp, t_eff

	alphafunc = (alpha) ->
		str = ""
		if tonumber(fstart) > 0
			str ..= ("\\alpha&HFF&\\t(%d,%s,1,\\alpha%s)")\format 0, fstart, alpha
		if tonumber(fend) > 0
			str ..= ("\\t(%d,%d,1,\\alpha&HFF&)")\format line.duration - tonumber(fend), line.duration
		str

	line.text = line.text\gsub "^{(.-)}", (block1) ->
		if fstart
			replaced = false
			block1 = block1\gsub "\\alpha(&H%x%x&)", (alpha) ->
				replaced = true
				alphafunc alpha
			unless replaced
				block1 ..= alphafunc alpha_from_style(line.styleref.color1)
		else
			block1 = block1\gsub "\\fade%(([%d]+),([%d]+),([%d]+),([%-%d]+),([%-%d]+),([%-%d]+),([%-%d]+)%)",
				(a, b, c, d, e, f, g) ->
					("\\alpha&H%02X&\\t(%s,%s,1,\\alpha&H%02X&)\\t(%s,%s,1,\\alpha&H%02X&)")\format(a, d, e, b, f, g, c)
		block1\gsub "\\t(%b())", lextrans
		'{' .. block1 .. '}'
	line.text = line.text\gsub "([^^])({.-})", (i, block) ->
		if fstart
			block = block\gsub "\\alpha(&H%x%x&)", alphafunc
		block\gsub "\\t(%b())", lextrans
		i..block

	line.text = line.text\gsub "\\(i?clip)(%b())", (clip, points) ->
		line.clips = clip
		points = points\gsub "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)", (leftX, topY, rightX, botY) ->
				("m %s %s l %s %s %s %s %s %s")\format(leftX, topY, rightX, topY, rightX, botY, leftX, botY),
			1
		points\gsub "%(([%d]*),?(.-)%)", (scl, clip) ->
				if line.sclip = tonumber(scl)
					line.rescaleclip = true
				else
					line.sclip = 1
				line.clip = clip,
			1
		'\\'..clip..'('..line.clip..')'
	return line

-------------------------------------------------------------------------------

ensuretags = (line, opts, styles, dim) ->

	with line
		._v = if .margin_v != 0 then .margin_v else .styleref.margin_v
		._l = if .margin_l != 0 then .margin_l else .styleref.margin_l
		._r = if .margin_r != 0 then .margin_r else .styleref.margin_r
		.ali = .text\match("\\an([1-9])") or .styleref.align

		.xpos, .ypos = .text\match "\\pos%(([%-%d%.]+),([%-%d%.]+)%)"
		if not .xpos -- insert position into line if not present.
			.xpos = fix.xpos[.ali%3+1] dim.x, ._l, ._r
			.ypos = fix.ypos[math.ceil(.ali/3)] dim.y, ._v
			.text = ("{\\pos(%d,%d)}%s")\format(.xpos, .ypos, .text)\gsub "^({.-)}{", "%1"

		.oxpos, .oypos = .text\match "\\org%(([%-%d%.]+),([%-%d%.]+)%)"
		.oxpos = .oxpos or .xpos
		.oypos = .oypos or .ypos
		.origindx = .xpos - .oxpos
		.origindy = .ypos - .oypos

		mergedtext = .text\gsub "}{", ""
		ovr_at_start = mergedtext\match "^{(.-)}"
		reformatblock = (block, rstyle=nil) ->
			for tag, str in pairs importanttags
				if opts[str.opt.a] and opts[str.opt.b]
					if not ovr_at_start or not ovr_at_start\match(tag.."[%-%d%.]+")
						scheck = line.styleref[str.key]
						srepl = if rstyle then rstyle[str.key] else scheck
						block ..= (tag.."%g")\format srepl if tonumber(scheck) != str.skip
			block

		block = reformatblock ""
		.text = ("{%s}%s")\format block, .text
		if ovr_at_start and block\len() > 0
			.text = .text\gsub "^({.-)}{", "%1"

		.text = .text\gsub "{([^}]*\\r)([^\\}]*)(.-)}",
			(before, rstyle, rest) ->
				styletab = styles[rstyle] or .styleref -- if \\r[stylename] is not a real style, reverts to regular \r
				"{"..before..rstyle..reformatblock("", styletab)..rest.."}"

-------------------------------------------------------------------------------

frame_by_frame = (sub, accd, opts, clipopts) ->

	local *

	newlines = {} -- table to stick indices of tracked lines into for cleanup.
	operations = {} -- create a table and put the necessary functions into it, which will save a lot of if operations in the inner loop. This was the most elegant solution I came up with.
	mocha = {}
	clipa = {}
	dim = {x:accd.meta.res_x, y:accd.meta.res_y}
	_ = nil

	main = ->

		printmem "Start of main loop"

		calc_abs_frame = (opts) -> if opts.stframe >= 0 then opts.stframe else accd.totframes + opts.stframe + 1

		if opts.linespath
			parse_input mocha, opts.linespath, accd.meta.res_x, accd.meta.res_y
			assert accd.totframes == mocha.flength, ("Number of frames selected (%d) does not match parsed line tracking data length (%d).")\format accd.totframes, mocha.flength
			spoof_table mocha, opts
			mocha.start = calc_abs_frame opts if not opts.relative
			clipa = mocha if opts.clip

		if clipopts.clippath
			parse_input clipa, clipopts.clippath, accd.meta.res_x, accd.meta.res_y
			assert accd.totframes == clipa.flength, ("Number of frames selected (%d) does not match parsed clip tracking data length (%d).")\format accd.totframes, clipa.flength
			opts.linear = false -- no linear mode with moving \clip, sorry
			opts.clip = true -- simplify things a bit
			spoof_table clipa, clipopts
			spoof_table mocha, opts, #clipa.xpos if not opts.linespath
			clipa.start = calc_abs_frame clipopts if not clipopts.relative

		for v in *accd.lines -- comment lines that were commented in the thingy
			derp = sub[v.num]
			derp.comment = true
			sub[v.num] = derp
			v.comment = false if not v.is_comment

		if opts.position
			operations["(\\pos)%(([%-%d%.]+,[%-%d%.]+)%)"] = possify
			operations["(\\org)%(([%-%d%.]+,[%-%d%.]+)%)"] = orginate if opts.origin

		if opts.scale then
			operations["(\\fsc[xy])([%d%.]+)"] = scalify
			operations["(\\[xy]?bord)([%d%.]+)"] = scalify if opts.border
			operations["(\\[xy]?shad)([%-%d%.]+)"] = scalify if opts.shadow
			operations["(\\blur)([%d%.]+)"] = scalify if opts.blur

		operations["(\\frz?)([%-%d%.]+)"] = rotate if opts.rotation

		printmem "End of table insertion"

		modo = if opts.linear then linearmodo else nonlinearmodo
		for currline in *accd.lines
			with currline
				printmem "Outer loop"
				.rstartf = .startframe - accd.startframe + 1 -- start frame of line relative to start frame of tracked data
				.rendf = .endframe - accd.startframe -- end frame of line relative to start frame of tracked data
				clipa.clipme = true if opts.clip and .clip
				.effect = "aa-mou" .. .effect
				calc_rel_frame = (opts) ->
					if tonumber(opts.stframe) >= 0 then currline.rstartf + opts.stframe - 1 else currline.rendf + opts.stframe + 1
				mocha.start = calc_rel_frame opts if opts.relative
				clipa.start = calc_rel_frame clipopts if clipopts.relative and clipa.clipme

				ensuretags currline, opts, accd.styles, dim

				.alpha = -datan( .ypos - mocha.ypos[mocha.start], .xpos - mocha.xpos[mocha.start] )
				.beta  = -datan( .oypos - mocha.ypos[mocha.start], .oxpos - mocha.xpos[mocha.start] ) if opts.origin
				.orgtext = .text -- tables are passed as references.

				modo currline

		for x = #sub, 1, -1
			if tostring(sub[x].effect)\match "^aa%-mou"
				table.insert newlines, x -- seems to work as intended

		return newlines -- yeah mang

	float2str = (f) -> ("%g")\format round(f, opts.posround)

	linearmodo = (currline) ->
		with currline
			one = aegisub.ms_from_frame aegisub.frame_from_ms .start_time
			two = aegisub.ms_from_frame aegisub.frame_from_ms(currline.start_time) + 1
			three = aegisub.ms_from_frame aegisub.frame_from_ms(currline.end_time) - 1
			four = aegisub.ms_from_frame aegisub.frame_from_ms .end_time
			maths = math.floor(0.5*(one+two) - currline.start_time) -- this voodoo magic gets the time length (in ms) from the start of the first subtitle frame to the actual start of the line time.
			mathsanswer = math.floor(0.5*(three+four) - currline.start_time) -- and this voodoo magic is the total length of the line plus the difference (which is negative) between the start of the last frame the line is on and the end time of the line.

			posmatch, _ = "(\\pos)%(([%-%d%.]+,[%-%d%.]+)%)" -- CHK
			if operations[posmatch]
				.text = .text\gsub posmatch,
					(tag, val) ->
						exes, whys = {}, {}
						for x in *{.rstartf, .rendf}
							cx, cy = val\match("([%-%d%.]+),([%-%d%.]+)")
							mochaRatios mocha, x
							cx = (cx + mocha.diffx)*mocha.ratx + (1 - mocha.ratx)*mocha.currx
							cy = (cy + mocha.diffy)*mocha.raty + (1 - mocha.raty)*mocha.curry
							r = math.sqrt((cx - mocha.currx)^2+(cy - mocha.curry)^2)
							cx = mocha.currx + r*dcos(.alpha + mocha.zrotd)
							cy = mocha.curry - r*dsin(.alpha + mocha.zrotd)
							table.insert exes, float2str(cx)
							table.insert whys, float2str(cy)
						s = ("\\move(%s,%s,%s,%s,%d,%d)")\format exes[1], whys[1], exes[2], whys[2], maths, mathsanswer
						debug "%s", s
						s
				_, operations[posmatch] = operations[posmatch], nil

			for pattern, func in pairs operations -- iterate through the necessary operations
				check_user_cancelled!
				.text = .text\gsub pattern,
					(tag, val) ->
						values = {}
						for x in *{.rstartf, .rendf}
							mochaRatios mocha, x
							table.insert values, func(val, currline, mocha, opts, tag)
						("%s%g\\t(%d,%d,1,%s%g)")\format tag, values[1], maths, mathsanswer, tag, values[2]

			sub[.num] = currline
			operations[posmatch] = _

	nonlinearmodo = (currline) ->
		with currline
			for x = .rendf, .rstartf, -1  -- new inner loop structure
				printmem "Inner loop"
				debug "Round %d", x
				aegisub.progress.title ("Processing frame %g/%g")\format x, .rendf - .rstartf + 1
				aegisub.progress.set (x - .rstartf)/(.rendf - .rstartf) * 100
				check_user_cancelled!

				.start_time = aegisub.ms_from_frame( accd.startframe + x - 1)
				.end_time   = aegisub.ms_from_frame( accd.startframe + x)

				if not .is_comment -- don't do any math for commented lines.
					.time_delta = .start_time - aegisub.ms_from_frame(accd.startframe)
					for kv in *.trans
						.text = transformate currline, kv
						check_user_cancelled!
					mochaRatios mocha, x

					for pattern, func in pairs operations -- iterate through the necessary operations
						.text = .text\gsub pattern, (tag, val) -> tag..func(val, currline, mocha, opts, tag)
						check_user_cancelled!

					if clipa.clipme
						.text = .text\gsub "\\i?clip%b()", (a) -> clippinate(currline, clipa, x), 1

					.text = .text\gsub '\1', ""

				sub.insert .num+1, currline
				.text = .orgtext

			sub.delete .num if global.delsourc

	main!

-------------------------------------------------------------------------------

mochaRatios = (mocha, x) ->
	with mocha
		.ratx = .xscl[x] / .xscl[.start]
		.raty = .yscl[x] / .yscl[.start]
		.diffx = .xpos[x] - .xpos[.start]
		.diffy = .ypos[x] - .ypos[.start]
		.zrotd = .zrot[x] - .zrot[.start]
		.currx = .xpos[x]
		.curry = .ypos[x]

-------------------------------------------------------------------------------

possify = (pos, line, mocha, opts) ->
	oxpos, oypos = pos\match "([%-%d%.]+),([%-%d%.]+)"
	nxpos, nypos = makexypos(tonumber(oxpos), tonumber(oypos), mocha)
	r = math.sqrt((nxpos - mocha.currx)^2 + (nypos - mocha.curry)^2)
	nxpos = mocha.currx + r*dcos(line.alpha + mocha.zrotd)
	nypos = mocha.curry - r*dsin(line.alpha + mocha.zrotd)
	debug "pos: (%f,%f) -> (%f,%f)", oxpos, oypos, nxpos, nypos
	return ("(%g,%g)")\format round(nxpos, opts.posround), round(nypos,opts.posround)

-------------------------------------------------------------------------------

orginate = (opos, line, mocha, opts) ->
	oxpos,oypos = opos\match("([%-%d%.]+),([%-%d%.]+)")
	nxpos,nypos = makexypos(tonumber(oxpos), tonumber(oypos), mocha)
	debug "org: (%f,%f) -> (%f,%f)", oxpos, oypos, nxpos, nypos
	return ("(%g,%g)")\format round(nxpos, opts.posround), round(nypos, opts.posround)

-------------------------------------------------------------------------------

makexypos = (xpos, ypos, mocha) ->
	nxpos = (xpos + mocha.diffx)*mocha.ratx + (1 - mocha.ratx)*mocha.currx
	nypos = (ypos + mocha.diffy)*mocha.raty + (1 - mocha.raty)*mocha.curry
	return nxpos, nypos

-------------------------------------------------------------------------------

clippinate = (line, clipa, iter) ->
	local cx, cy, ratx, raty, diffrz
	with clipa
		cx, cy = .xpos[iter], .ypos[iter]
		ratx   = .xscl[iter]/.xscl[.start]
		raty   = .yscl[iter]/.yscl[.start]
		diffrz = .zrot[iter] - .zrot[.start]
	debug "cx: %f cy: %frx: %f ry: %f\nfrz: %f\n", cx, cy, ratx, raty, diffrz

	sclfac = 2^(line.sclip - 1)
	clip = line.clip\gsub "([%.%d%-]+) ([%.%d%-]+)", (x, y) ->
		xo, yo = x, y
		x = (tonumber(x) - clipa.xpos[clipa.start]*sclfac) * ratx
		y = (tonumber(y) - clipa.ypos[clipa.start]*sclfac) * raty
		r = math.sqrt(x^2+y^2)
		alpha = datan(y, x)
		x = cx*sclfac + r*dcos(alpha - diffrz)
		y = cy*sclfac + r*dsin(alpha - diffrz)
		debug "Clip: %d %d -> %d %d", xo, yo, x, y
		if line.rescaleclip
			x *= 1024/sclfac
			y *= 1024/sclfac
		("%d %d")\format round(x), round(y)

	scale = if line.rescaleclip then "11," else ""
	return ("\\%s(%s)")\format line.clips, scale..clip

transformate = (line, trans) ->
	t_s = trans[1] - line.time_delta
	t_e = trans[2] - line.time_delta
	debug "Transform: %d,%d -> %d,%d", trans[1], trans[2], t_s, t_e
	return line.text\gsub "\\t%b()", ("\\%st(%d,%d,%g,%s)")\format(string.char(1), t_s, t_e, trans[3], trans[4]), 1

scalify = (scale, line, mocha, opts, tag) ->
	newScale = scale*mocha.ratx -- sudden camelCase for no reason
	debug "%s: %f -> %f", tag\sub(2), scale, newScale
	return round(newScale, opts.sclround)

rotate = (rot, line, mocha, opts) ->
	zrot = rot + mocha.zrotd
	debug "frz: -> %f", zrot
	return round(zrot, opts.rotround)

-------------------------------------------------------------------------------

munch = (sub, sel) ->
	changed = false
	for num in *sel
		check_user_cancelled!
		l1 = sub[num - 1]
		l2 = sub[num]
		if l1.text == l2.text and l1.effect == l2.effect
			l1.end_time = l2.end_time
			debug "Munched line %d", num
			sub[num - 1] = l1
			sub.delete num
			changed = true
	return changed

-------------------------------------------------------------------------------

cleanup = (sub, sel, opts) -> -- make into its own macro eventually.

	opts = opts or {}
	local linediff
	cleantrans = (cont) -> -- internal function because that's the only way to pass the line difference to it
		t_s, t_e, ex, eff = cont\sub(2,-2)\match "([%-%d]+),([%-%d]+),([%d%.]*),?(.+)"
		return ("%s")\format eff if tonumber(t_e) <= 0 -- if the end time is less than or equal to zero, the transformation has finished. Replace it with only its contents.
		return "" if tonumber(t_s) > linediff or tonumber(t_e) < tonumber(t_s) -- if the start time is greater than the length of the line, the transform has not yet started, and can be removed from the line.
		return ("\\t(%s,%s,%s)")\format t_s, t_e, eff if tonumber(ex) == 1 or ex == "" -- if the exponential factor is equal to 1 or isn't there, remove it (just makes it look cleaner)
		return ("\\t(%s,%s,%s,%s)")\format t_s, t_e, ex, eff -- otherwise, return an untouched transform.

	ns = {}
	for i, v in ipairs sel
		aegisub.progress.title ("Castrating gerbils: %d/%d")\format i, #sel

		lnum = sel[#sel - i + 1]
		with line = sub[lnum] -- iterate backwards (makes line deletion sane)
			linediff = .end_time - .start_time
			.text = .text\gsub "}"..string.char(6).."{", "" -- merge sequential override blocks if they are marked as being the ones we wrote
			.text = .text\gsub string.char(6), "" -- remove superfluous marker characters for when there is no override block at the beginning of the original line
			.text = .text\gsub "\\t(%b())", cleantrans -- clean up transformations (remove transformations that have completed)
			.text = .text\gsub "{}", "" -- I think this is irrelevant. But whatever.

			for a in .text\gmatch "{(.-)}"
				aegisub.progress.set math.random(100) -- professional progress bars
				transforms = {}
				.text = .text\gsub "\\(i?clip)%(1,m", "\\%1(m"

				a = a\gsub "(\\t%b())",
					(transform) ->
						debug "Cleanup: %s found", transform
						table.insert transforms, transform
						string.char(3)

				for k, v in pairs alltags
					_, num = a\gsub(v, "")
					a = a\gsub v, "", num - 1

				for trans in *transforms
					a = a\gsub string.char(3), trans, 1

				.text = .text\gsub "{.-}", string.char(1)..a..string.char(2), 1 -- I think...

			.text = .text\gsub string.char(1), "{"
			.text = .text\gsub string.char(2), "}"
			.effect = .effect\gsub "aa%-mou", "", 1
			sub[lnum] = line

	sel = dialog_sort sub, sel, opts.sortd if opts.sortd != "Default"

-------------------------------------------------------------------------------

dialog_sort = (sub, sel, sor) ->
	sortF = ({
		Time:   (l, n) -> {key: l.start_time, num: n, data: l }
		Actor:  (l, n) -> {key: l.actor,      num: n, data: l }
		Effect: (l, n) -> {key: l.effect,     num: n, data: l }
		Style:  (l, n) -> {key: l.style,      num: n, data: l }
		Layer:  (l, n) -> {key: l.layer,      num: n, data: l }
	})[sor] -- thanks, tophf //np

	lines = {}
	for v in *sel
		table.insert lines, sortF( sub[v], v )
		check_user_cancelled!

	strt = sel[1] -- not strictly necessary
	table.sort lines, (a, b) -> a.key > b.key or (a.key == b.key and a.num > b.num)

	for i = #sel, 1, -1
		sub.delete sel[i] -- BALEET (in reverse because they are not necessarily contiguous)
		check_user_cancelled!

	sel = {}
	for i, v in ipairs lines
		aegisub.progress.title ("Sorting gerbils: %d/%d")\format i, #lines
		aegisub.progress.set i/#lines*100
		table.insert sel, strt
		sub.insert strt, v.data -- not sure this is the best place to do this but owell
		check_user_cancelled!

	return sel

-------------------------------------------------------------------------------

readconf = (conf, guitab) ->
	debug "Opening config file: %s", conf
	cf = io.open conf, 'r'
	return nil if not cf

	valtab = {}
	thesection = nil
	debug "Reading config file..."
	for line in cf\lines()
		section = line\match "#(%w+)"
		if section
			valtab[section] = {}
			thesection = section
			debug "Section: %s", thesection
		elseif thesection == nil
			return nil
		else
			key, val = splitconf line
			debug "Read: %s -> %s", key, tostring(val\tobool())
			valtab[thesection][key\gsub("^ +", "")] = val\tobool()

	cf\close()

	for section, sectab in pairs guitab
		for ident, value in pairs valtab[section]
			if section == "global"
				debug "Set: global.%s = %s (%s)", ident, tostring(value), type(value)
				sectab[ident] = value
			else
				if sectab[ident]
					debug "Set: gui.%s.%s = %s (%s)", section, ident, tostring(value), type(value)
					sectab[ident].value = value
	return true

writeconf = (conf, optab) ->
	cf = io.open conf, 'w+'
	if not cf
		warn 'Config write failed! Check that %s exists and has write permission.\n', cf
		return nil

	configlines = {}
	for section, tab in pairs optab
		table.insert configlines, ("#%s\n")\format(section)
		if section == "global"
			for ident, value in pairs tab
				table.insert configlines, ("  %s:%s\n")\format(ident, tostring(value))
		else
			for field in *(guiconf[section])
				if tab[field] ~= nil
					-- (e.g. when clipconf == {}, don't overwrite all the config with "nil")
					table.insert configlines, ("  %s:%s\n")\format(field, tostring(tab[field]))

	for v in *configlines
		debug "Write: %s -> config", v\gsub("^ +", "")
		cf\write v

	cf\close()
	debug "Config written to %s", conf
	return true

splitconf = (s) ->
	s\gsub("[\r\n]+", "")\match("^(.-):(.*)$")

configscope = ->
	return config_file if not config_file or re.match(tostring(config_file), [[^(?:/|[A-Z]:\\)]], re.ICASE)
	cfs = aegisub.decode_path("?script/"..config_file)
	if f = io.open(cfs)
		f\close()
		return cfs
	return aegisub.decode_path("?user/"..config_file)

-------------------------------------------------------------------------------

confmaker = ->

	onetime_init!

	lvaltab = {}
	conf = configscope()
	if not readconf conf, {main: gui.conf, clip: gui.clip, global: global}
		warn "Config read failed!"

	for key, value in pairs global
		gui.conf[key].value = value if gui.conf[key]
	gui.conf.enccom.value = encpre[global.encoder] or gui.conf.enccom.value

	btns = {
			conf: makebuttons {{ok:"&Write"}, {local:"Write &local"}, {clip:"&\\clip..."}, {cancel:"&Abort"}}
			clip: makebuttons {{ok:"&Write"}, {local:"Write &local"}, {cancel:"&Cancel"}, {abort:"&Abort"}}
		}
	dlg = "conf"

	while true
		local clipconf, button, config

		with btns[dlg]
			button, config = aegisub.dialog.display(gui[dlg], .__list, .__namedlist)

		switch button
			when btns.conf.clip
				dlg = "clip"
				continue

			when btns.conf.ok, btns.conf.local, btns.clip.ok, btns.clip.local
				clipconf = clipconf or {}
				conf = aegisub.decode_path("?script/"..config_file) if button == "Write local"
				config.enccom = encpre[config.encoder] or config.enccom if global.encoder != config.encoder

				for key, value in pairs global
					global[key] = config[key]
					config[key] = nil

				for field in *guiconf.clip
					clipconf[field] = gui.clip[field].value if clipconf[field] == nil

				writeconf conf, {main: config, clip: clipconf, global: global}
				break

			else
				if dlg == "conf" or button == btns.clip.abort
					aegisub.cancel!
				else
					dlg = "conf"
					continue

-------------------------------------------------------------------------------

trimnthings = (sub, sel) ->

	onetime_init!

	conf = configscope()
	if conf
		if not readconf conf, {global: global}
			warn "Failed to read config!"

	tokens = {}
	with tokens
		.encbin = global.encbin
		.prefix = aegisub.decode_path global.prefix
		.nl = "\n"
		collecttrim sub, sel, tokens

		.input = getvideoname(sub)\gsub("[A-Z]:\\", "")\gsub(".+[^\\/]-[\\/]", "")
		assert not .input\match("?dummy"), "No dummy videos allowed. Sorry."

		.inpath = aegisub.decode_path "?video/"
		.index = .input\match "(.+)%.[^%.]+$"
		.output = .index -- huh.

		if global.gui_trim
			gui.t.input.value  = .input
			gui.t.index.value  = .index
			gui.t.startf.value = .startf
			gui.t.endf.value   = .endf
			gui.t.output.value = .output

			button, opts = aegisub.dialog.display gui.t
			return if not button

			for k, v in pairs opts do tokens[k] = v
			.startt = aegisub.ms_from_frame .startf
			.endt   = aegisub.ms_from_frame .endf
			.lenf = .endf - .startf
			.lent = .endt - .startt

		.startt, .endt, .lent = .startt/1000, .endt/1000, .lent/1000

	platform = ({
			{ext:'.bat', exec:'""%s""',  postexec:'\nif errorlevel 1 (echo Error & pause & del %0) else del %0'}
			{ext:'.sh',  exec:'sh "%s"', postexec:' 2>&1\nrm $0'}
		})[if winpaths then 1 else 2]

	encsh = tokens.prefix.."a-mo.encode"..platform.ext
	sh = io.open encsh, "w+"
	assert sh, "Encoding command could not be written. Check your prefix."
	sh\write( global.enccom\gsub("#(%b{})", (token) -> tokens[token\sub(2, -2)])..platform.postexec )
	sh\close!
	output = io.popen platform.exec\format encsh
	outputstr = output\read!
	debug outputstr
	output\close!
	-- if ret != 0 then error "Encoding failed!\n"

-------------------------------------------------------------------------------

collecttrim = (sub, sel, tokens) ->
	with tokens
		s = sub[sel[1]]
		.startt, .endt = s.start_time, s.end_time
		for v in *sel
			l = sub[v]
			lst, let = l.start_time, l.end_time
			.startt = lst if lst < .startt
			.endt = let if let > .endt

		.startf = aegisub.frame_from_ms(.startt)
		.endf   = aegisub.frame_from_ms(.endt) - 1
		.lenf = .endf - .startf + 1
		.lent = .endt - .startt

-------------------------------------------------------------------------------

-- [[ borrowed from the lua-users wiki (single character split ONLY) ]]--
string.split = (sep) =>
	sep, fields = sep or ":", {}
	string.gsub @, "([^#{sep}]+)", (c) -> table.insert fields, c
	fields

string.tobool = =>
	switch @\lower()
		when 'true'  then true
		when 'false' then false
		else @

table.tostring = (t) ->
	return tostring(t) if type(t) != 'table'

	s = ''
	i = 1
	while t[i] != nil
		s ..= ', ' if #s != 0
		s ..= table.tostring t[i]
		i += 1

	for k, v in pairs t
		if type(k) != 'number' or k > i
			s ..= ', ' if #s != 0
			key = type(k) == 'string' and k or '['..table.tostring(k)..']'
			s = s..key..'='..table.tostring(v)

	return '{'..s..'}'

-------------------------------------------------------------------------------

-- [[ Functions for more easily handling angles specified in degrees ]]--
dcos  = (a) -> math.cos math.rad a
dacos = (a) -> math.deg math.acos a
dsin  = (a) -> math.sin math.rad a
dasin = (a) -> math.deg math.asin a
dtan  = (a) -> math.tan math.rad a
datan = (y, x) -> math.deg math.atan2 y, x

-- Functions for giving the default position of a line, given its alignment
-- and margins. The alignment can be split into x and y as follows:
-- x = an%3+1 -> 1 = right aligned (3,6,9), 2 = left aligned (1,4,7),
-- and 3 = centered (2,5,8); y = math.ceil(an/3) -> 1 = bottom (1,2,3),
-- 2 = middle (4,5,6), 3 = top (7,8,9). In the below functions, `sx` is the
-- script width, `sy` is the script height, `l` is the line's left margin,
-- `r` is the line's right margin, and `v` is the line's vertical margin.
fix = {
	xpos: {
		(sx, l, r) -> sx - r
		(sx, l, r) -> l
		(sx, l, r) -> sx/2
	}
	ypos: {
		(sy, v) -> sy - v
		(sy, v) -> sy/2
		(sy, v) -> v
	}
}

check_user_cancelled = ->
	error "User cancelled" if aegisub.progress.is_cancelled()

-- [[ expand compact dialog definition {"class",x,y,w,h} to standard key:value pairs]]--
conformdialog = (dlg) ->
	for _, e in pairs dlg
		for k, v in pairs {class:e[1], x:e[2], y:e[3], width:e[4], height:e[5]}
			e[k] = v
	dlg

makebuttons = (extendedlist) -> -- example: {{ok:'&Add'}, {load:'Loa&d...'}, {cancel:'&Cancel'}}
	btns = {__list:{}, __namedlist:{}}
	for L in *extendedlist
		for k,v in pairs L
			btns[k] = v
			btns.__namedlist[k] = v
			table.insert btns.__list, v
	btns

windowerr = (bool, message) ->
	if not bool
		aegisub.dialog.display {{class:"label", label:message}}, {"&Close"}, {cancel:"&Close"}
		error message

printmem = (a) ->
	debug "%s memory usage: %gkB", tostring(a), collectgarbage "count"

debug = (...) ->
	aegisub.log 4, ...
	aegisub.log 4, '\n'

warn = (...) ->
	aegisub.log 2, ...
	aegisub.log 2, '\n'

round = (num, idp) -> -- borrowed from the lua-users wiki (all of the intelligent code you see in here is)
	mult = 10^(idp or 0)
	math.floor(num * mult + 0.5) / mult

getvideoname = (sub) ->
	for x = 1, #sub
		if sub[x].key == "Video File"
			return sub[x].value\gsub "^ ", ""

isvideo = ->
	return true if aegisub.frame_from_ms(0)
	return false, "Validation failed: you don't have a video loaded."

-------------------------------------------------------------------------------

aegisub.register_macro "Motion Data - Apply", "Applies properly formatted motion tracking data to selected subtitles.",
	init_input, isvideo

aegisub.register_macro "Motion Data - Trim", "Cuts and encodes the current scene for use with motion tracking software.",
	trimnthings, isvideo

if config_file
	aegisub.register_macro "Motion Data - Config", "Full config management.",
		confmaker
