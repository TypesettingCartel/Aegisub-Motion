local log
version = '##__TRIMHANDLER_VERSION__##'

haveDepCtrl, DependencyControl = pcall require, 'l0.DependencyControl'

if haveDepCtrl
	version = DependencyControl {
		name: 'TrimHandler'
		:version
		description: 'A class for encoding video clips.'
		author: 'torque'
		url: 'https://github.com/TypesettingTools/Aegisub-Motion'
		moduleName: 'a-mo.TrimHandler'
		feed: 'https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json'
		{
			{ 'a-mo.Log',  version: '##__LOG_VERSION__##' }
		}
	}
	log = version\requireModules!

else
	log  = require 'a-mo.Log'

windows = jit.os == "Windows"

class TrimHandler
	@version: version

	@windows: windows

	existingPresets: {
		"x264", "ffmpeg"
	}

	-- Set up encoder presets.
	defaults: {
		x264:    '"#{encbin}" --crf 16 --tune fastdecode -i 250 --fps 24000/1001 --sar 1:1 --index "#{prefix}/#{index}.index" --seek #{startf} --frames #{lenf} --output-depth 8 --output-csp i420 -o "#{prefix}/#{output}[#{startf}-#{endf}].mp4" "#{inpath}/#{input}"'
		ffmpeg:  '"#{encbin}" -ss #{startt} -an -sn -i "#{inpath}/#{input}" -q:v 1 -vsync passthrough -frames:v #{lenf} "#{prefix}/#{output}[#{startf}-#{endf}]-%05d.jpg"'
		-- avs2pipe: 'echo FFVideoSource("#{inpath}#{input}",cachefile="#{prefix}#{index}.index").trim(#{startf},#{endf}).ConvertToRGB.ImageWriter("#{prefix}/#{output}-[#{startf}-#{endf}]\\",type="png").ConvertToYV12 > "#{temp}/a-mo.encode.avs"\nmkdir "#{prefix}#{output}-[#{startf}-#{endf}]"\n"#{encbin}" video "#{temp}/a-mo.encode.avs"\ndel "#{temp}/a-mo.encode.avs"'
		-- vapoursynth:
	}

	-- Example trimConfig:
	-- trimConfig = {
	-- 	-- The prefix is the directory the output will be written to. It
	-- 	-- is passed through aegisub.decode_path.
	-- 	prefix: "?video"

	-- 	-- The name of the built in encoding preset to use. Overridden by
	-- 	-- command if that is neither nil nor an empty string.
	-- 	preset: "x264"

	-- 	-- The path of the executable used to actually do the encoding.
	-- 	-- Full path is recommended as the shell environment may be
	-- 	-- different than expected on non-windows systems.
	-- 	encBin: "C:\x264.exe"

	-- 	-- A custom encoding command that can be used to override the
	-- 	-- built-in defaults. Usable token documentation to come.
	-- 	-- Overrides preset if that is set.
	-- 	command: nil

	-- 	-- Script should attempt to create prefix directory.
	-- 	makePfix: nil

	-- 	-- Script should attempt to log output of the encoding command.
	-- 	writeLog: true
	-- }
	new: ( trimConfig ) =>
		@tokens = { }
		if trimConfig.command != nil
			trimConfig.command = trimConfig.command\gsub "[\t \r\n]*$", ""
			if trimConfig.command != ""
				@command = trimConfig.command
			else
				@command = @defaults[trimConfig.preset]
		else
			@command = @defaults[trimConfig.preset]

		@makePrefix = trimConfig.makePfix
		@writeLog   = trimConfig.writeLog

		with @tokens
			.temp = aegisub.decode_path "?temp"
			-- For some reason, aegisub appends / to the end of ?temp but not
			-- other tokens.
			finalTemp = .temp\sub -1, -1
			if finalTemp == '\\' or finalTemp == '/'
				.temp = .temp\sub 1, -2
			.encbin = trimConfig.encBin
			.prefix = aegisub.decode_path trimConfig.prefix
			.inpath = aegisub.decode_path "?video"
			.log    = aegisub.decode_path "#{.temp}/a-mo.encode.log"

		getVideoName @

	getVideoName = =>
		with @tokens
			video = aegisub.project_properties!.video_file
			if video\len! == 0
				log.windowError "Aegisub thinks you have no attached video file, yet this script somehow passed the validation macro.\nTheoretically it should be impossible to get this error."
			if video\match "^?dummy"
				log.windowError "I can't encode that dummy video for you."
			.input = video\gsub( "^[A-Z]:\\", "", 1 )\gsub ".+[^\\/]-[\\/]", "", 1
			.index = .input\match "(.+)%.[^%.]+$"
			.output = .index

	calculateTrimLength: ( lineCollection ) =>
		with @tokens
			.startt = lineCollection.startTime / 1000
			.endt   = lineCollection.endTime / 1000
			.lent   = .endt - .startt
			.startf = lineCollection.startFrame
			.endf   = lineCollection.endFrame - 1
			.lenf   = lineCollection.totalFrames

	performTrim: =>
		with platform = ({
				[true]:  {
					pre: @tokens.temp
					ext: ".ps1"
					-- This needs to be run from cmd or it will not work.
					exec: 'powershell -c iex "$(gc "%s" -en UTF8)"'
					preCom: (@makePrefix and "mkdir -Force \"#{@tokens.prefix}\"; & " or "& ")
					postCom: (@writeLog and " 2>&1 | Out-File #{@tokens.log} -en UTF8; if($LASTEXITCODE -ne 0) {echo \"If there is no log before this, your encoder is not a working executable or your encoding command is invalid.\" | ac -en utf8 #{@tokens.log}; exit 1}" or "") .. "; exit 0"
					execFunc: ( encodeScript ) ->
						-- clear out old logfile because it doesn't get overwritten
						-- when certain errors occur.
						if @writeLog
							logFile = io.open @tokens.log, 'wb'
							logFile\close! if logFile
						success = os.execute encodeScript
						if @writeLog and not success
							logFile = io.open @tokens.log, 'r'
							unless logFile
								log.windowError "Could not read log file #{@tokens.log}.\nSomething has gone horribly wrong."
							encodeLog = logFile\read '*a'
							logFile\close!
							log.warn "\nEncoding error:"
							log.warn encodeLog
							log.windowError "Encoding failed. Log has been printed to progress window."
						elseif not success
							log.windowError "Encoding seems to have failed but you didn't write a log file."
				}
				[false]: {
					pre: @tokens.temp
					ext: ".sh"
					exec: 'sh "%s"'
					preCom: @makePrefix and "mkdir -p \"#{@tokens.prefix}\"\n" or ""
					postCom: " 2>&1; if [[ $? -ne 0 ]]; then echo \"If there is no log before this, your encoder is not a working executable or your encoding command is invalid.\"; false; fi"
					execFunc: ( encodeScript ) ->
						logFile = io.popen encodeScript, 'r'
						encodeLog = logFile\read '*a'
						-- When closing a file handle created with io.popen,
						-- file:close returns the same values returned by
						-- os.execute.
						success = logFile\close!
						unless success
							log.warn "\nEncoding error:"
							log.warn encodeLog
							log.windowError "Encoding failed. Log has been printed to progress window."
				}
			})[windows]
			-- check encoder binary exists
			encoder = io.open @tokens.encbin, "rb"
			unless encoder
				log.windowError "Encoding binary (#{@tokens.encbin}) does not appear to exist."
			encoder\close!

			encodeScript = aegisub.decode_path "#{.pre}/a-mo.encode#{.ext}"
			encodeScriptFile = io.open encodeScript, "w+"
			unless encodeScriptFile
				log.windowError "Encoding script could not be written.\nSomething is wrong with your temp dir (#{.pre})."
			encodeString = .preCom .. @command\gsub( "#{(.-)}", ( token ) -> @tokens[token] ) .. .postCom
			if windows
				encodeString = encodeString\gsub "`", "``"
			log.debug encodeString
			encodeScriptFile\write encodeString
			encodeScriptFile\close!
			.execFunc .exec\format encodeScript

if haveDepCtrl
	return version\register TrimHandler
else
	return TrimHandler
