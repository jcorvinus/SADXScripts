utility SADXSplineExporter "SADX 2P Path Exporter" width:162 height:225
(
	label lbl1 "Export File Name:" pos:[16,10] width:108 height:15
	editText pathText "" pos:[10, 24] width:140 height:20
	
	button importButton "Export" pos:[20,219] width:116 height:23 enabled:true

	button browseButton "Browse" pos:[20,48]  width:116 height:23 enabled:true
	button helpButton "IMPORTANT INFO" pos:[20,195] width:116 height:23 enabled:true
	
	global filePath = ""
	global pathValid = false
	
	global currentName = ""
	
	on browseButton pressed do
	(
		filePath = getSaveFileName caption:"Pick a path to save to" types:"C File|*.c"
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
		messageBox "This tool is incomplete - update this help doc pls."
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
			
			pathStream = openFile(filePath) mode:"w+"
			V_count = numKnots currentShape
			
			nameString = "P2Path " + currentShape.name + "[] = {\n"
			format nameString to:pathStream
				
			for i=1 to v_count do
			(					
				position = GetKnotPoint currentShape 1 i
				outputPosString = "	{ 0, {" + position.x as string + "f," + position.y as string + "f," + position.z as string + "f } }"
				
				if (i != v_count) do -- output comma at the end of string built line
				(			
					outputPosString = outputPosString + ","
				)
				
				outputPosString = outputPosString + "\n"
				format outputPosString to:pathStream
			)
			
			-- add closing bracket and semicolon here
			format "};" to:pathStream
			
			close pathStream
			
			messageBox "Complete!"
		)
		else
		(
			messageBox "Cannot export non-spline objects"
		)
	) -- end importButton press 
) -- end utility