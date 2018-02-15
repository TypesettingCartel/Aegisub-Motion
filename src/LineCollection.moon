local log, Line
version = '##__LINECOLLECTION_VERSION__##'

haveDepCtrl, DependencyControl = pcall require, 'l0.DependencyControl'

if haveDepCtrl
	version = DependencyControl {
		name: 'LineCollection'
		:version
		description: 'A class for handling collections of lines.'
		author: 'torque'
		url: 'https://github.com/TypesettingTools/Aegisub-Motion'
		moduleName: 'a-mo.LineCollection'
		feed: 'https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json'
		{
			{ 'a-mo.Log',  version: '##__LOG_VERSION__##'  }
			{ 'a-mo.Line', version: '##__LINE_VERSION__##' }
		}
	}
	log, Line = version\requireModules!

else
	log  = require 'a-mo.Log'
	Line = require 'a-mo.Line'

frameFromMs = aegisub.frame_from_ms

class LineCollection
	@version: version

	@fromAllLines: ( sub, validationCb, selectLines ) =>
		sel = { }
		for i = 1, #@sub
			table.insert( sel, i ) if @sub[i].class == "dialogue"
		@ sub, sel, validationCb, selectLines

	new: ( @sub, sel, validationCb, selectLines = true ) =>
		@lines = { }

		meta = getmetatable @
		if 'function' != type meta.__index
			metaIndex = meta.__index
			meta.__index = ( index ) =>
				if 'number' == type index
					@lines[index]
				else
					metaIndex[index]

		if type( sel ) == "table" and #sel > 0
			@collectLines sel, validationCb, selectLines
			if frameFromMs 0
				@getFrameInfo!
		else
			for i = #@sub, 1, -1
				if @sub[i].class != "dialogue" then
					@firstLineNumber = i + 1
					@lastLineNumber = i + 1
					break

	-- This method should update various properties such as
	-- (start|end)(Time|Frame).
	addLine: ( line, validationCb = (-> return true), selectLine = true, index = false ) =>
		if validationCb line
			line.parentCollection = @
			line.inserted = false
			line.selected = selectLine
			line.number = index == true and line.number or index or nil

			-- if @startTime is unset, @endTime should damn well be too.
			if @startTime
				if @startTime > line.start_time
					@startTime = line.start_time

				if @endTime < line.end_time
					@endTime = line.end_time

			else
				@startTime = line.start_time
				@endTime   = line.end_time

			if @hasMetaStyles
				line.styleRef = @styles[line.style]

			if @hasFrameInfo
				line.startFrame = frameFromMs line.start_time
				line.endFrame = frameFromMs line.end_time
				@startFrame  = frameFromMs @startTime
				@endFrame    = frameFromMs @endTime
				@totalFrames = @endFrame - @startFrame

			table.insert @lines, line

	generateMetaAndStyles: =>
		@styles = { }
		@meta   = { }
		for i = 1, #@sub
			line = @sub[i]

			if line.class == "style"
				@styles[line.name] = line
			-- not going to bother porting all the special-case bullshit over
			-- from karaskel.
			elseif line.class == "info"
				@meta[line.key] = line.value

			elseif line.class == "dialogue"
				break

		unless next @styles
			log.windowError "No styles could be found and I guarantee that's gonna break something."

		@hasMetaStyles = true

	collectLines: ( sel, validationCb = (( line ) -> return not line.comment), selectLines = true ) =>
		unless @hasMetaStyles
			@generateMetaAndStyles!

		dialogueStart = 0
		for x = 1, #@sub
			if @sub[x].class == "dialogue"
				dialogueStart = x - 1 -- start line of dialogue subs
				break

		@startTime  = @sub[sel[1]].start_time
		@endTime    = @sub[sel[1]].end_time
		@lastLineNumber = 0

		for i = #sel, 1, -1
			with line = Line @sub[sel[i]], @
				if validationCb line
					.number = sel[i]
					@firstLineNumber = math.min .number, @firstLineNumber or .number
					@lastLineNumber = math.max .number, @lastLineNumber
					.inserted = true
					.hasBeenDeleted = false
					.selected = selectLines
					.humanizedNumber = .number - dialogueStart
					.styleRef = @styles[.style]

					if .start_time < @startTime
						@startTime = .start_time

					if .end_time > @endTime
						@endTime = .end_time

					table.insert @lines, line

	getFrameInfo: =>

		for line in *@lines
			line.startFrame = frameFromMs line.start_time
			line.endFrame   = frameFromMs line.end_time

		@startFrame  = frameFromMs @startTime
		@endFrame    = frameFromMs @endTime
		@totalFrames = @endFrame - @startFrame
		@hasFrameInfo = true

	callMethodOnAllLines: ( methodName, ... ) =>
		for line in *@lines
			line[methodName] line, ...

	combineIdenticalLines: =>
		lastLine = @lines[1]
		linesToSkip = { }
		for i = 2, #@lines
			log.checkCancellation!

			if lastLine\combineWithLine @lines[i]
				linesToSkip[#linesToSkip+1] = @lines[i]
				@shouldInsertLines = true
				continue
			else lastLine = @lines[i]
		@deleteLines linesToSkip

	-- The third value passed to the callback is for progress reporting only,
	-- and the fourth is the actual index.
	runCallback: ( callback, reverse ) =>
		lineCount = #@lines
		if reverse
			for index = lineCount, 1, -1
				callback @, @lines[index], lineCount - index + 1, index
		else
			for index = 1, lineCount
				callback @, @lines[index], index, index

	deleteLines: ( lines = @lines, doShift = true ) =>
		if lines.__class == Line
			lines = { lines }

		lineSet = {line,true for _,line in pairs lines when not line.hasBeenDeleted}
		-- make sure all lines are unique and have not actually been already removed
		lines = [k for k,v in pairs lineSet]

		@sub.delete [line.number for line in *lines when line.inserted]

		@lastLineNumber = @firstLineNumber
		shift = #lines or 0
		for line in *@lines
			if lineSet[line]
				line.hasBeenDeleted = true
				shift -= line.inserted and 1 or 0
			elseif not line.hasBeenDeleted and line.inserted
				line.number -= doShift and shift or 0
				@lastLineNumber = math.max(line.number, @lastLineNumber)

	insertLines: =>
		toInsert = [line for line in *@lines when not (line.inserted or line.hasBeenDeleted)]
		tailLines, numberedLines = {}, {}

		for i = 1, #toInsert
			line = toInsert[i]
			if line.number
				numberedLines[#numberedLines + 1] = line
				line.i = i
			else
				tailLines[#tailLines + 1] = line
				line.number = @lastLineNumber + i
				line.inserted = true

		table.sort numberedLines, ( a, b ) ->
			return (a.number < b.number) or (a.number == b.number) and (a.i < b.i)

		for line in *numberedLines
			@sub.insert line.number, line
			line.inserted = true
			@lastLineNumber = math.max @lastLineNumber, line.number

		tailLineCnt, chunkSize = #tailLines, 1000
		if tailLineCnt > 0
			for i = 1, tailLineCnt, chunkSize
				chunkSize = math.min chunkSize, tailLineCnt - i + 1
				@sub.insert @lastLineNumber + i, unpack tailLines, i, i+chunkSize-1
			@lastLineNumber = math.max @lastLineNumber, tailLines[tailLineCnt].number

	replaceLines: =>
		if @shouldInsertLines
			@insertLines!
		else
			for line in *@lines
				if line.inserted and not line.hasBeenDeleted
					@sub[line.number] = line

	getSelection: =>
		sel = [line.number for line in *@lines when line.selected and line.inserted and not line.hasBeenDeleted]
		return sel, sel[#sel]

	__newindex: ( index, value ) =>
		if 'number' == type index
			@lines[index] = value
		else
			rawset @, index, value

	__len: =>
		#@lines 

	__ipairs: =>
		iterator = ( tbl, i ) ->
			i += 1
			value = tbl[i]
			if value
				i, value
		iterator, @lines, 0

	-- There's no real reason to use pairs, but I've preserved it anyways
	__pairs: =>
		next, @lines, nil

if haveDepCtrl
	return version\register LineCollection
else
	return LineCollection
