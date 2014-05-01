utility SA_MeshExporter "SA Compiled Mesh Exporter" width:162 height:300
(
	GroupBox optionbox "Options" pos:[7,6] width:142 height:176
	label keyopts "Destination Pointer Key:" pos:[13,25]
	label lblbaddr "Base Address:" pos:[13,140]
	edittext baseaddr "" pos:[13,155] width:120 height:20 text:"0"
	radiobuttons keyselect labels:#("Sonic.exe", "Chrmodels.dll", "Stg.bin", "Zero Key") default:1 columns:1 pos:[13,40]
	edittext outpath "" pos:[3,198] width:145 height:20
	label lbl1 "Output Path" pos:[9,185] width:133 height:13
	button exp_exec "Export Data" pos:[8,268] width:139 height:26
	button btn_browse "Browse" pos:[7,220] width:78 height:26	
	checkbox exp_vcolors "Export Vcolors" pos:[13,115]
	
	on keyselect changed state do
	(
	if keyselect.state == 1  do	filekey = 0x400000 -- sonic.exe
	if keyselect.state == 2 do	 filekey = 0x10000000 -- chrmodels.dll
	if keyselect.state == 3 do	 filekey = 0xC900000 --stg.bin
	if keyselect.state == 4 do	filekley = 0
	)
	on exp_exec pressed do
	(
	
	filekey = 0x400000
	
	-- get keys
	if keyselect.state == 1  do	filekey = 0x400000 -- sonic.exe
	if keyselect.state == 2 do	 filekey = 0x10000000 -- chrmodels.dll
	if keyselect.state == 3 do	 filekey = 0xC900000 --stg.bin
	if keyselect.state == 4 do filekey = 0
	
	-- create meshfile
	meshpath = outpath.text + "\out.msh"
	meshfile = fopen meshpath "wb+"
	-- create output file
	njpath = outpath.text + "\out.nj"
	njfile = fopen njpath "wb+"
	attachpath = outpath.text + "\out.att"
	
	--========= Material Generation / Face Arrays =========--
	-- get material/mesh totals
	mesh = selection[1]
	ConvertTo mesh (Editable_Mesh)
	--AddModifier mesh (MeshSelect())
	poly_total = mesh.numFaces
	-- ids = mesh.material.materialIDList --Go through the material ids
	mesh_total = 0
	-- setselectionlevel mesh #face
	IDlist = #()
	mesh_facelists=#()

	for j=1 to mesh.numFaces do
	(
		-- get id from face
		Curr_ID = getFaceMatID mesh j
		--format "Face: % matID: % \n" j Curr_ID
		-- have we found this ID before?  no?
		idfound = finditem IDlist Curr_ID
		if  idfound == 0 then
		(
			-- format "New MatID found on face %, building array to hold facelist\n" j
			append IDlist Curr_ID
			append mesh_facelists #(Curr_ID,#(j))
		)
		else
		(
			-- format "adding face % to facelist for ID %, index: % \n" j Curr_ID idfound 
			append mesh_facelists[idfound][2] j
		)
	)
print mesh_facelists
mesh_total = IDlist.count
-- format "mesh_facelists[1][1] %\n" mesh_facelists[1][1]

	/* ============ Writing Material Data lol =============== */
	for i=1 to IDlist.count do
	(
	WriteByte njfile 0xb2 -- start exporting material data
	WriteByte njfile 0xb2
	WriteByte njfile 0xb2
	WriteByte njfile 0xFF
	WriteByte njfile 0xFF
	WriteByte njfile 0xFF
	WriteByte njfile 0xFF
	WriteByte njfile 0xFF
	WriteByte njfile 0x00
	WriteByte njfile 0x00
	WriteByte njfile 0x30
	WriteByte njfile 0x41
	WriteByte njfile (IDlist[i]-1)
	WriteByte njfile 0x00
	WriteByte njfile 0x00
	WriteByte njfile 0x00
	WriteByte njfile 0x00
	WriteByte njfile 0x24
	WriteByte njfile 0x20
	WriteByte njfile 0x94
	)

		--========= Mesh / poly / uv Generation =========--
		for i=1 to IDlist.count do -- Mesh data loop
		(
			WriteByte meshfile (i - 1) -- matID to use
			WriteByte meshfile 0x00 -- Face type, always use Tris
			WriteShort meshfile mesh_facelists[i][2].count -- poly_total for this mesh
			-- format "mesh total: %\n" mesh_facelists[i][2].count
			poly_offset = ftell(njfile) + (baseaddr.text as integer+filekey)
			WriteLong meshfile poly_offset
			WriteLong meshfile 0
			WriteLong meshfile 0
			currentpoly = 0
			-- cw changes here:			
			face_list = mesh_facelists[i][2]
			face_bits = face_list as bitarray
			setFaceSelection mesh face_bits
			
			--_curSel = getFaceSelection mesh
			_curSel = face_list
				for j=1 to _curSel.count do
				(
					p = getFace mesh _curSel[j]
					p[1] = p[1] - 1
					p[2] = p[2] - 1
					p[3] = p[3] - 1
					writeShort njfile p[1]
					writeShort njfile p[2]
					writeShort njfile p[3]
				)
				VCptr = 0
				
				if (exp_vcolors.checked) then
				(
				VCptr = ftell(njfile) + (baseaddr.text as integer + filekey)
				for j=1 to _curSel.count do
					(
					vcface = getVCFace mesh _cursel[j] -- should return an array, of size 3
					v1 = getVertColor mesh vcface[1]
					v2 = getVertColor mesh vcface[2]
					v3 = getVertcolor mesh vcface[3]
					WriteByte njfile v1.blue
					WriteByte njfile v1.green
					WriteByte njfile v1.red
					WriteByte njfile 0xff
					WriteByte njfile v2.blue
					WriteByte njfile v2.green
					WriteByte njfile v2.red
					WriteByte njfile 0xff
					WriteByte njfile v3.blue
					WriteByte njfile v3.green
					WriteByte njfile v3.red
					WriteByte njfile 0xff
					)
				)
				
			WriteLong meshfile VCptr -- vcolor slot	
			
			uvptr = ftell(njfile) + baseaddr.text as integer + filekey
			WriteLong meshfile uvptr
				-- write uv data offset
			if keyselect.state != 3 do WriteLong meshfile 0
				-- should be NULL (end of struct)
			currentpoly = 0
				for j=1 to _curSel.count do
				(
					tvface = (getTVFace mesh _curSel[j]) -- should return an array of size 3
					face1 = getTVert mesh tvface[1]
					face2 = getTVert mesh tvface[2]
					face3 = getTVert mesh tvface[3]
					face1[1] = face1[1] * 255
					face1[2] = face1[2] * 255
					face2[1] = face2[1] * 255
					face2[2] = face2[2] * 255
					face3[1] = face3[1] * 255
					face3[2] = face3[2] * 255
					writeShort njfile face1[1]
					writeShort njfile face1[2]
					writeShort njfile face2[1]
					writeShort njfile face2[2]
					writeShort njfile face3[1]
					writeShort njfile face3[2]
				)
			)
			
		fflush meshfile
		fclose meshfile
		meshptr = ftell(njfile) + baseaddr.text as integer + filekey -- remember this for building attach struct
		fflush njfile
		fclose njfile
		DOSCommand ("copy /B /Y "+njpath+"+"+meshpath+" "+njpath) -- merging files to put mesh data where it belongs
		-- print ("copy /B /Y "+njpath+"+"+meshpath+" "+njpath)
		
	--=====Done Meshing=====--
	njfile = fopen njpath "rb+"
	attachfile = fopen attachpath "wb+"
	fseek njfile 0 #seek_end -- go to end of file lol
	vtptr = ftell(njfile) + baseaddr.text as integer + filekey
	WriteLong attachfile vtptr -- vt offsetf
	--========= Vertex Tree / Vertex Normals Generation =========--
			old_x = selection[1].pos.x
			old_y = selection[1].pos.y
			old_z = selection[1].pos.z
			
			old_pos = selection[1].pos
			old_rx = selection[1].rotation.x_rotation
			old_ry = selection[1].rotation.y_rotation
			old_rz = selection[1].rotation.z_rotation
			
			old_rot = selection[1].rotation
		
			--========= zero exporter fix ===========
			selection[1].pos = [0,0,0]
			selection[1].rotation = quat 0 0 0 1
			selection[1].rotation.x_rotation = 0
			selection[1].rotation.y_rotation = 0
			selection[1].rotation.z_rotation = 0
			
			V_count = mesh.numVerts
		
			for i = 1 to V_count do
			(
				p = (GetVert mesh i)
				writeFloat njfile p.x
				writeFloat njfile p.y
				writeFloat njfile p.z
			)
			
			allVerts = for i in 1 to mesh.numVerts collect getVert mesh i
			vDist = for i in allVerts collect distance i mesh.center
			sort vDist	
			A_radius = vDist[vDist.count] -- Asphere Radius
			vnptr = ftell(njfile) + baseaddr.text as integer + filekey
			WriteLong attachfile vnptr
			WriteLong attachfile V_count
			WriteLong attachfile meshptr
			WriteLong attachfile (baseaddr.text as integer + filekey)
			WriteShort attachfile mesh_total
			WriteShort attachfile mesh_total
			center = mesh.center
			WriteFloat attachfile center[1]
			WriteFloat attachfile center[2]
			WriteFloat attachfile center[3]
			WriteFloat attachfile A_radius
			if keyselect.state != 3 do	WriteFloat attachfile 0 -- NULLs need not be present in DC files
			
			--guessing here? - cw
			vn_count = v_count
			
			for i = 1 to vn_count do
			(
				p = (GetNormal mesh i)
					writeFloat njfile p.x
					writeFloat njfile p.y
					writeFloat njfile p.z
			)
			-- Don't forget to do normals before re-orienting model in scene!
			-- ===== restore old values ==========
			selection[1].rotation = old_rot
			selection[1].rotation.x_rotation = old_rx
			selection[1].rotation.y_rotation = old_ry
			selection[1].rotation.z_rotation = old_rz
			selection[1].pos = old_pos
			
	--=====Done Verts=====--
	
	fflush attatchfile
	fclose attachfile
	fflush njfile
	fclose njfile
	
	DOSCommand ("copy /B /Y " + njpath + "+" + attachpath + " " + njpath) -- merging files to put attach data where it belongs
	-- print ("copy /B /Y " + njpath + "+" + attachpath + " " + njpath)
	
	messagebox ("Done Exporting!")
	
	)
	on btn_browse pressed do
	(
		filename = getSavePath caption:"Select a folder to export compiled model data to:" initialDir:(getDir #maxroot)
	
		if (filename != undefined) then
		outpath.text = filename
		
		if (filename == undefined) then
		messagebox "Please input a directory"
	)
)