utility SADXSplineImporter "SADX 2P Path Importer" width:162 height:175
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
		filePath = getOpenFileName caption:"Pick a path file to load" types:"C File|*.c"
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
				currentShape = splineShape prefix:"p2b_path_"
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
			else if (pathType == ".c") then
			(
				--=Import SATools path format=--
				pathStream = openFile(filePath) mode:"rt"
				nodeName = "p2_path_" + getFileNameFile filePath
				
				parseString = readLine pathStream
				tempStream = parseString as stringStream				
				tempToken = readDelimitedString tempStream "{"
				
				currentShape = splineShape name:nodeName
				addNewSpline currentShape
				
				filePosition =  filepos pathStream
				print filePosition as string
				
				while not (eof pathStream) do
				(		
					positionString = readLine pathStream
					tempStream = positionString as stringStream
					
					positionSplit = filterString positionString "{"
					
					if (positionSplit.count == 3) do -- if count is one, we have the end of the file
					(		
						knotPosition = [0,0,0]						
						
						positionSplit = filterString positionSplit[3] " ,}"
						
						tempToken = readDelimitedString tempStream ","
						knotPosition.x = positionSplit[1] as float -- set x position						
						
						tempToken = readDelimitedString tempStream ","
						knotPosition.y = positionSplit[2] as float -- set y position
						
						tempToken = readDelimitedString tempStream ","
						knotPosition.z = positionSplit[3] as float -- set z position
						
						print knotPosition
						addKnot currentShape 1 #corner #line knotPosition
					)
				)
				
				--= done importing=--
				updateShape currentShape
				
				select currentShape
				close pathStream
				
				enableSceneRedraw()
				actionMan.executeAction 0 "311" -- zoom extents
			)
		) -- end filepath check
		
	) -- end importButton press
	
)