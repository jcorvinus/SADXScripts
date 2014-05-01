utility SADXSplineExporter "SADX Path Exporter" width:162 height:225
(
	label lbl1 "Export File Name:" pos:[16,10] width:108 height:15
	editText pathText "" pos:[10, 24] width:140 height:20
	--checkBox enableFlip "Enable Y-Z flip" pos:[18,12]
	button importButton "Export" pos:[20,219] width:116 height:23 enabled:true
	label lbl2 "Pick a Code value" pos:[16, 78] width:108 height:15
	radiobuttons codeButtons labels:#("Loop/Ground Path", "Camera Path", "Air/Wind Path", "Other") default:1
	editText codeText "" pos:[25,165] width:80 height:15
	button browseButton "Browse" pos:[20,48]  width:116 height:23 enabled:true
	button helpButton "IMPORTANT INFO" pos:[20,195] width:116 height:23 enabled:true
	
	global filePath = ""
	global pathValid = false
	
	global currentName = ""
	
	on SADXSplineExporter open do
	(
		codeText.text = 0 as string
	)
	
	on browseButton pressed do
	(
		filePath = getSaveFileName caption:"Pick a path to save to" types:"INI File|*.ini"
		if(filePath != undefined) then 
		(
			pathText.Text = filePath
			pathValid = true
		) else
		(
			pathValid = false
		)
	)
	
	on helpButton pressed do
	(
		messageBox "This exporter creates path files for SADXPC. Use the browse button to find a location to save to. It only exports one at a time, and it exports the currently selected scene node. The scene node must be a shape or splineshape."
		messageBox "The Code value determines how the path will be used. More specifically, it is the address of the function that uses said path. If set to other, a hexadecimal value must be used. 0 is fine. The most commonly used values are provided for you."
		messageBox "This exporter does NOT calculate proper x or y rotation values, as the method for generating them is not yet known. However, many path objects (like the running path and camera path) ignore the rotation/angle data anyways."
	)
	
	on importButton pressed do
	(
		if(pathValid == false) then
		(
			messageBox("Invalid save destination")
			exit
		)

		if(selection.count != 1) do
		(
			messageBox "Exporter can only process one shape at a time."
			exit
		)
		
		if(canConvertTo selection[1] splineShape) then
		(
			currentShape = convertToSplineShape selection[1]
			
			if(numSplines currentShape != 1) do
			(
				messageBox "Your shape has too many splines in it. Only one spline is allowed per shape."
				exit
			)
			
			codeValue = 0x0
			
			if(codeButtons.state == 1) then
			(
				codeValue = 0x4BB1F0
			)
			else if (codeButtons.state == 2) then
			(
				codeValue = 0x4F9D80
			)
			else if (codeButtons.state == 3) then
			(
				codeValue = 0x4DF020
			)
			else if(codeButtons.state == 4) do
			(
				-- checking to see if a valid code value has been entered
				concatString = "0x" + codeText.text
				codeValue = concatString as integer
			)
		
			pathStream = openFile(filePath) mode:"w+"
			
			-- get Total Distance
			V_count = numKnots currentShape
			totalDistance = 0.0
		
			for i = 1 to (V_count - 1) do
			(
				nextIndex = i + 1
				location1 = (GetKnotPoint currentShape 1 i)
				location2 = (GetKnotPoint currentShape 1 nextIndex)
				
				distPos = distance location1 location2
				
				totalDistance += distPos
			)
			
			-- write total distance
			TDOutputString = "TotalDistance=" + totalDistance as string + "\n"
			format TDOutputString to:pathStream
			
			-- write code
			format "Code=" to: pathStream
			codeOutput = formattedprint codeValue format:#x to:pathStream
			codeOutput = codeOutput + "\n"
			format codeOutput  to:pathStream
			
			for i=1 to v_count do
			(
				offByOne = i - 1
				knotIDString = "[" + offByOne as string + "]" + "\n"
				format knotIDString to: pathStream
				format "XRotation=0000\n" to: pathStream
				format "YRotation=0000\n" to: pathStream
				

				if (i != v_count) do
				(			
					nextIndex = i + 1
					pos1 = (GetKnotPoint currentShape 1 i)
					pos2 = (GetKnotPoint currentShape 1 nextIndex)
					dist = distance pos1 pos2
					
					distanceString = "Distance=" + dist as string + "\n"
					format distanceString to: pathStream
				)
				
				position = GetKnotPoint currentShape 1 i
				outputPosString = "Position=" + position.x as string + "," + position.y as string + "," + position.z as string + "\n"
				format outputPosString to:pathStream
			)
			
			close pathStream
			
			messageBox "Complete!"
		)
		else
		(
			messageBox "Cannot export non-spline objects"
		)
	) -- end importButton press 
) -- end utility