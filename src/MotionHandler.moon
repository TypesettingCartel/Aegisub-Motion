LineCollection = require 'a-mo.LineCollection'
Math           = require 'a-mo.Math'
Line           = require 'a-mo.Line'
log            = require 'a-mo.Log'

class MotionHandler

	new: ( @lineCollection, @lineTrackingData, @rectClipData, @vectClipData ) =>
		-- Create a local reference to the options table.
		@options = @lineCollection.options

		setCallbacks @

	setCallbacks = =>
		@callbacks = { }

		if @options.main.xPosition or @options.main.yPosition

			@callbacks["(\\pos)%(([%-%d%.]+,[%-%d%.]+)%)"] = position

		if @options.main.origin
			@callbacks["(\\org)%(([%-%d%.]+,[%-%d%.]+)%)"] = origin

		if @options.main.xScale then
			@callbacks["(\\fsc[xy])([%d%.]+)"] = scale
			if @options.main.border
				@callbacks["(\\[xy]?bord)([%d%.]+)"] = scale
			if @options.main.shadow
				@callbacks["(\\[xy]?shad)([%-%d%.]+)"] = scale
			if @options.main.blur
				@callbacks["(\\blur)([%d%.]+)"] = scale

		if @options.main.zRotation
			@callbacks["(\\frz?)([%-%d%.]+)"] = rotate

		if @rectClipData
			@callbacks['(\\i?clip)(%([%-%d%.]+,[%-%d%.]+,[%-%d%.]+,[%-%d%.]+%))'] = rectangularClip

		if @vectClipData
			@callbacks['(\\i?clip)(%([^,]-%))'] = vectorClip

		@resultingCollection = LineCollection @lineCollection.sub
		@resultingCollection.shouldInsertLines = true
		for line in *@lineCollection.lines
			if @options.main.linear and not (@options.main.origin and line.hasOrg) and not ((@rectClipData or @vectClipData) and line.hasClip)
				line.method = linear
			else
				line.method = nonlinear

	applyMotion: =>
		-- The lines are collected in reverse order in LineCollection so
		-- that we don't need to do things in reverse here.
		for line in *@lineCollection.lines
			with line

				-- start frame of line relative to start frame of tracked data
				.relativeStart = .startFrame - @lineCollection.startFrame + 1
				-- end frame of line relative to start frame of tracked data
				.relativeEnd = .endFrame - @lineCollection.startFrame

				.method @, line

		return @resultingCollection

	linear = ( line ) =>
		with line
			startFrameTime = aegisub.ms_from_frame aegisub.frame_from_ms .start_time
			frameAfterStartTime = aegisub.ms_from_frame aegisub.frame_from_ms(.start_time) + 1
			frameBeforeEndTime = aegisub.ms_from_frame aegisub.frame_from_ms(.end_time) - 1
			endFrameTime = aegisub.ms_from_frame aegisub.frame_from_ms .end_time
			-- Calculates the time length (in ms) from the start of the first
			-- subtitle frame to the actual start of the line time.
			beginTime = math.floor 0.5*(startFrameTime + frameAfterStartTime) - .start_time
			-- Calculates the total length of the line plus the difference
			-- (which is negative) between the start of the last frame the
			-- line is on and the end time of the line.
			endTime = math.floor 0.5*(frameBeforeEndTime + endFrameTime) - .start_time

			for pattern, callback in pairs @callbacks
				log.checkCancellation!
				.text = .text\gsub pattern, ( tag, value ) ->
					values = { }
					for frame in *{ line.relativeStart, line.relativeEnd }
						@lineTrackingData\calculateCurrentState frame
						values[#values+1] = callback @, value, frame
					("%s%s\\t(%d,%d,%s%s)")\format tag, values[1], beginTime, endTime, tag, values[2]

			if @options.main.xPosition or @options.main.yPosition
				.text = .text\gsub "\\pos(%b())\\t%((%d+,%d+),\\pos(%b())%)", ( start, time, finish ) ->
					"\\move" .. start\sub( 1, -2 ) .. ',' .. finish\sub( 2, -2 ) .. ',' .. time .. ")"

			@resultingCollection\addLine Line line

	nonlinear = ( line ) =>
		for frame = line.relativeEnd, line.relativeStart, -1
			with line
				aegisub.progress.set (frame - .relativeStart)/(.relativeEnd - .relativeStart) * 100
				log.checkCancellation!

				newStartTime = aegisub.ms_from_frame( @lineCollection.startFrame + frame - 1 )
				newEndTime   = aegisub.ms_from_frame( @lineCollection.startFrame + frame )

				timeDelta = newStartTime - aegisub.ms_from_frame( @lineCollection.startFrame + .relativeStart )

				newText = .text\gsub "\\fade(%b())", ( fade ) ->
					a1, a2, a3, t1, t2, t3, t4 = fade\match("(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)")
					t1, t2, t3, t4 = tonumber( t1 ), tonumber( t2 ), tonumber( t3 ), tonumber( t4 )
					-- beautiful.
					t1 -= timeDelta
					t2 -= timeDelta
					t3 -= timeDelta
					t4 -= timeDelta
					("\\fade(%s,%s,%s,%d,%d,%d,%d)")\format a1, a2, a3, t1, t2, t3, t4

				-- In theory, this is more optimal if we loop over the frames on
				-- the outside loop and over the lines on the inside loop, as
				-- this only needs to be calculated once for each frame, whereas
				-- currently it is being calculated for each frame for each
				-- line. However, if the loop structure is changed, then
				-- inserting lines into the resultingCollection would need to be
				-- more clever to compensate for the fact that lines would no
				-- longer be added to it in order.
				@lineTrackingData\calculateCurrentState frame

				-- iterate through the necessary operations
				for pattern, callback in pairs @callbacks
					newText = newText\gsub pattern, ( tag, value ) ->
						tag .. callback @, value, frame

				-- Update transforms without detokenizing them. This ended up
				-- being a bit hackier than I intended.
				newTransforms = { }
				for transform in *.transforms
					table.insert newTransforms, {
						start:  transform.start - timeDelta
						end:    transform.end   - timeDelta
						accel:  transform.accel
						effect: transform.effect
					}

				@resultingCollection\addLine Line line, nil, { text: newText, start_time: newStartTime, end_time: newEndTime, transforms: newTransforms }

	position = ( pos, frame ) =>
		x, y = pos\match "([%-%d%.]+),([%-%d%.]+)"
		x, y = positionMath x, y, @lineTrackingData
		("(%g,%g)")\format Math.round( x, @options.main.posRound ), Math.round( y, @options.main.posRound )

	positionMath = ( x, y, data ) ->
		x = (tonumber( x ) - data.xStartPosition)*data.xRatio
		y = (tonumber( y ) - data.yStartPosition)*data.yRatio
		radius = math.sqrt( x^2 + y^2 )
		alpha  = Math.dAtan( y, x )
		x = data.xCurrentPosition + radius*Math.dCos( alpha - data.zRotationDiff )
		y = data.yCurrentPosition + radius*Math.dSin( alpha - data.zRotationDiff )
		return x, y

	absolutePosition = ( pos, frame ) =>
		("(%g,%g)")\format Math.round( @lineTrackingData.xPosition[frame], @options.main.posRound ), Math.round( @lineTrackingData.xPosition[frame], @options.main.posRound )

	-- Needs to be fixed.
	origin = ( origin, frame ) =>
		ox, oy = origin\match("([%-%d%.]+),([%-%d%.]+)")
		ox, oy = positionMath ox, oy, @lineTrackingData
		("(%g,%g)")\format Math.round( ox, @options.main.posRound ), Math.round( oy, @options.main.posRound )

	scale = ( scale, frame ) =>
		scale *= @lineTrackingData.xRatio
		tostring Math.round scale, @options.main.sclRound

	rotate = ( rotation, frame ) =>
		rotation += @lineTrackingData.zRotationDiff
		tostring Math.round rotation, @options.main.rotRound

	rectangularClip = ( clip, frame ) =>
		@rectClipData\calculateCurrentState frame

		return clip\gsub "([%.%d%-]+),([%.%d%-]+)", ( x, y ) ->
			x, y = positionMath x, y, @rectClipData
			("%g,%g")\format Math.round( x, 2 ), Math.round( y, 2 )

	vectorClip = ( clip, frame ) =>
		-- This is redundant if vectClipData is the same as
		-- lineTrackingData.
		@vectClipData\calculateCurrentState frame

		return clip\gsub "([%.%d%-]+) ([%.%d%-]+)", ( x, y ) ->
			x, y = positionMath x, y, @vectClipData
			("%g %g")\format Math.round( x, 2 ), Math.round( y, 2 )
