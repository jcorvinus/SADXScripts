utility SADXSplineImporter "SADX Path Importer" width:162 height:175
(
	label lbl1 "Pick a file to open:" pos:[16,44] width:108 height:15
	editText pathText "" pos:[10,67] width:140 height:20
	button importButton "Import" pos:[20,131] width:116 height:23 enabled:true
	button browseButton "Browse" pos:[20,99] width:116 height:23 enabled:true
	
	global filePath = ""
	global pathValid = false
	global pathType = ""
	
	global nodeCount = 0
	
	on browseButton pressed do
	(
		filePath = getOpenFileName caption:"Pick a path file to load" types:"INI File|*.ini|SA Path|*.sapath"
		if(filePath != undefined) then 
		(
			pathText.Text = filePath
			pathValid = true
			
			pathType = getfileNametype filePath
			print pathType
		) else
		(
			pathValid = false
		)
	)
	
	on importButton pressed do
	(
		if(pathValid == false) then messageBox("Please select a file to load")
		else
		(
			if(pathType == ".sapath") then
			(
				-- Import raw binary file --
				fileSize = getFileSize(filePath)
				
				if((mod fileSize 0x14) != 0) do
				(
					messageBox ("Invalid File.")
					exit
				)
				
				nodeCount = fileSize / 0x14			
				pathStream = fOpen(filePath) "rb"
				currentShape = splineShape prefix:"sapath"
				addNewSpline currentShape
				
				for currentNode = 0 to nodeCount - 1 do
				(
					unknown1 = readShort pathStream
					unknown2 = readShort pathStream
					
					distanceToNext = readFloat PathStream
					
					xPos = readFloat pathStream
					yPos = readFloat pathStream
					zPos = readFloat pathStream
					
					knotLocation = [xPos,yPos,zPos] as point3
					
					addKnot currentShape 1 #corner #line knotLocation
				)
				
				updateShape currentShape			
				fClose pathStream
			)
			else if (pathType == ".ini") then
			(
				--=Import SATools path format=--
				pathStream = openFile(filePath) mode:"rt"
				nodeName = "path_" + getFileNameFile filePath
				
				parseString = readLine pathStream
				tempStream = parseString as stringStream				
				tempToken = readDelimitedString tempStream "="
				
				if(tempToken == "TotalDistance") then
				(
					parseString = readLine pathStream
					tempStream = parseString as stringStream				
					tempToken = readDelimitedString tempStream "="
					
					if(tempToken != "Code") do
					(
						messageBox "Error occured - 'code' token was expected, but not found."
						exit
					)
					
					tempToken = readDelimitedString tempStream "="
					nodeName = nodeName + "_" + tempToken
					
					currentShape = splineShape name:nodeName
					addNewSpline currentShape
					
					filePosition =  filepos pathStream
					print filePosition as string
					
					currentKnot = 0
					while not (eof pathStream) do
					(
						lastKnot = false
						
						parseString = readLine pathStream
						confirmString = "[" + currentKnot as string + "]"
						
						if(parseString != confirmString) do
						(
							messageBox "Unexpected knot order. Output is corrupt, trying to make the best of it..."
							
							updateShape currentShape			
							close pathStream
							exit
						)
						
						-- x_rot and y_rot values are currently unknown, and probably couldn't be represented by MAX anyways. Maybe they're user flags instead?
						skipToNextLine pathStream
						skipToNextLine pathStream
						
						distanceFilePos = filePos pathStream
						
						-- if 'Distance' is present, we know we are not on the last knot.
						parseString = readLine pathStream
						tempStream = parseString as stringStream
						tempToken = readDelimitedString tempStream "="
						
						if(tempToken != "Distance") do
						(
							lastKnot = true
							seek pathStream distanceFilePos
						)
						
						knotPosition = [0,0,0]
						positionString = readLine pathStream
						tempStream = positionString as stringStream
						
						tempToken = readDelimitedString tempStream "="
						tempToken = readDelimitedString tempStream "="
						
						tempStream = tempToken as stringStream
						
						tempToken = readDelimitedString tempStream ","
						knotPosition.x = tempToken as float -- set x position						
						
						tempToken = readDelimitedString tempStream ","
						knotPosition.y = tempToken as float -- set y position
						
						tempToken = readDelimitedString tempStream ","
						knotPosition.z = tempToken as float -- set z position
						
						print knotPosition
						addKnot currentShape 1 #corner #line knotPosition
						
						if(lastKnot == true) do break
						currentKnot = currentKnot + 1
					)
					
					--= done importing=--
					updateShape currentShape
				)
				else
				(
					messageBox "File supplied is not a valid path file. Aborting."
				)
				
				select currentShape
				close pathStream
				
				enableSceneRedraw()
				actionMan.executeAction 0 "311" -- zoom extents
			)
		) -- end filepath check
		
	) -- end importButton press
	
)