utility SA_MeshExporter "Nodetable / obj exporter" width:162 height:300
(
	GroupBox optionbox "Options" pos:[7,6] width:142 height:45
	checkbox exp_vcolors "Export Vcolors" pos:[13,25] checked:true
	label lbl1 "Output Path" pos:[9,60] width:133 height:13
	edittext outpath "" pos:[3,75] width:145 height:20
	button btn_browse "Browse" pos:[7,100] width:78 height:26	
	button exp_exec "Export Data" pos:[8,140] width:139 height:26
	
	on exp_exec pressed do
	(
	
	scenepath = outpath.text + "\\nodetable.txt"
	scenefile = createfile scenepath
	
	mtlpath = outpath.text + "\\scene.mtl"
	mtlfile = createfile mtlpath
	
	/*-------------Begin Creating Materal File--------------*/
	submatcount = getNumSubmtls (meditMaterials[1])
	for m=1 to submatcount do
	(
		currentsub = GetsubMtl meditMaterials[1] m
		format "newmtl %\n" m to:mtlfile
		format "Ka 1 1 1"
		diff = currentsub.diffuse
		diffscale = #()
		diffscale[1] = diff.red as float
		diffscale[2] = diff.green as float
		diffscale[3] = diff.blue as float
		diffscale[1] = diffscale[1]/255
		diffscale[2] = diffscale[2]/255
		diffscale[3] = diffscale[3]/255
		format "Kd % % %\n" diffscale[1] diffscale[2] diffscale[3] to:mtlfile
		spec = currentsub.specular
		specscale = #()
		specscale[1] = spec.red as float
		specscale[2] = spec.green as float
		specscale[3] = spec.blue as float
		specscale[1] = specscale[1]/255
		specscale[2] = specscale[2]/255
		specscale[3] = specscale[3]/255
		format "Ks % % %\n" specscale[1] specscale[2] specscale[3] to:mtlfile
		format "illum 1\n" to:mtlfile
		texid = m-1
		format "texid %\n" texid to:mtlfile
		format "Map_Ka %\n" currentsub.diffuseMap.filename to:mtlfile
		format "Map_KD %\n\n" currentsub.diffuseMap.filename to:mtlfile
	)
	/*----------------END Creating Material File----------------*/
	
	/*-------------Sanitizing input selection-----------------*/
	removeList = #()
	for sanitNode = 1 to selection.count do
	(
		if(classof selection[sanitNode] != editable_mesh) and (classof selection[sanitNode] != editable_poly) and (classof selection[sanitNode] != edit_mesh) and (classof selection[sanitNode] != edit_poly) do
		(
			append removeList selection[sanitNode]
		)
	)
	
	for sanitNode = 1 to removeList.count do
	(
		deselect removeList[sanitNode]
	)
	/*-------------End input sanitization-----------------------*/

	masterskiplist = #()
	meshflags = #() as bitarray	
	append meshflags 1 -- used for Vcolor
	append meshflags 2 -- used for TexCoords
	nodetotal = selection.count
	format "ver 1.5;\n" to:scenefile
	format "node count %;\n\n" nodetotal to:scenefile
	for n=1 to nodetotal do
	(
		skipflag = false
		mesh = selection[n].mesh
		if masterskiplist.count > 1 do
		(
			for skipcounter = 1 to masterskiplist.count do
			(
				if selection[n].name == masterskiplist[skipcounter] then skipflag = true
				else format "1:% 2:% \n" selection[n].name masterskiplist[skipcounter]
			)
		)
		
		if skipflag == false then
		(			
		format "node %; \n" (n-1) to:scenefile
		obj_exp_path = (outpath.text + "\\" + (n-1) as string + ".obj")
		objfile = createfile obj_exp_path
		format "mtllib scene.mtl\n" to:objfile
		format "g node_% #% \n" (n-1) selection[n].name to:objfile
	
		old_x = selection[n].pos.x
		old_y = selection[n].pos.y
		old_z = selection[n].pos.z

		old_pos = selection[n].pos
		
		camRotEuler = quatToEuler2 selection[n].rotation.controller.value
		
		format "pos % % %; \n" old_x old_y old_z to:scenefile
		format "rot % % %; \n\n" camRotEuler.x camRotEuler.y camRotEuler.z to:scenefile
	
		/*-------------Vertex Exporting------------*/
		newnode = copy selection[n]
		newnode.pos = [0,0,0]
		newnode.rotation = quat 0 0 0 1
		newnode.rotation.x_rotation = 0
		newnode.rotation.y_rotation = 0
		newnode.rotation.z_rotation = 0
		convertToMesh newnode
	
		--V_count = selection[n].mesh.numVerts
		V_count = newnode.numVerts
		
		for i = 1 to V_count do
		(
				p = (GetVert newnode i)
				format "v % % % \n" p.x p.y p.z to:objfile
		)
		
		for i = 1 to V_count do
		(
			p = (GetNormal newnode i)
			format "vn % % % \n" p.x p.y p.z to:objfile 
		)
		
		delete newnode
		
		--========= Material Generation / Face Arrays =========--
		-- get material/mesh totals
		mesh = selection[n].mesh
		--ConvertTo mesh (Editable_Mesh)
		poly_total = mesh.numFaces
		mesh_total = 0
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

		--========= Mesh / poly / uv Generation =========--

		if GetNumTVerts (selection[n].mesh) > 0 then
		(
			meshflags[1] = true
			totaltverts = getNumTVerts selection[n].mesh
			for i=1 to totaltverts do -- Mesh data loop
			(
				tvert = getTVert selection[n].mesh i
				format "vt % % #index: %\n" tvert[1] tvert[2] i to:objfile
			)
		) else if GetNumTVerts (selection[n].mesh) == 0 then meshflags[1] = false
		
		for i=1 to IDlist.count do -- Mesh data loop
		(
			-- cw changes here:			
			face_list = mesh_facelists[i][2]
			face_bits = face_list as bitarray
			setFaceSelection mesh face_bits
			
			--_curSel = getFaceSelection mesh
			_curSel = face_list
			currentpoly = 0

		
			if (exp_vcolors.checked and getNumCPVVerts (selection[n].mesh) > 0) then
			(
			meshflags[2] = true
			vcVerts = getNumCPVVerts selection[n].mesh
				for j=1 to vcverts do
					(
					vcface = getVertColor selection[n].mesh j -- should return an array, of size 3
					format "vc % % % %\n" (vcface.alpha as integer) (vcface.red as integer) (vcface.green as integer) (vcface.blue as integer) to:objfile
					)
			) else if GetNumCPVVerts (selection[n].mesh) == 0 then meshflags[2] = false
		)
		
		currentpoly = 0	
		
		for i=1 to IDlist.count do -- Mesh data loop
		(
				-- cw changes here:			
				face_list = mesh_facelists[i][2]
				face_bits = face_list as bitarray
				setFaceSelection mesh face_bits
			
				--_curSel = getFaceSelection mesh
				_curSel = face_list
				currentpoly = 0
				currID = getFaceMatID selection[n].mesh _curSel[1]
					format "\n" to:objfile
				format "usemtl % \n" currID to:objfile
				for j=1 to _curSel.count do
				(
					p = getFace mesh _curSel[j]
					if meshflags[1] == true and meshflags[2] == true then
					(
						tvface = (getTVFace mesh _curSel[j]) -- should return an array of size 3
						vcface = (getVCFace mesh _curSel[j]) -- should return an array of size 3
						format "f %/%/%/% %/%/%/% %/%/%/% \n" (p[1] as integer) (tvface[1] as integer) (p[1] as integer) (vcface[1] as integer) (p[2] as integer) (tvface[2] as integer) (p[2] as integer) (vcface[2] as integer) (p[3] as integer) (tvface[3] as integer) (p[3] as integer) (vcface[3] as integer) to:objfile 
					)
					else if meshflags[1] == true and meshflags[2] == false then
					(
						tvface = (getTVFace mesh _curSel[j])
						format "f %/%/% %/%/% %/%/%\n" (p[1] as integer) (tvface[1] as integer) (p[1] as integer) (p[2] as integer) (tvface[2] as integer) (p[2] as integer) (p[3] as integer) (tvface[3] as integer) (p[3] as integer) to:objfile
					)
					else if meshflags[1] == false and meshflags[2] == false then
					(
						format "f %//% %//% %//%\n" (p[1] as integer) (p[1] as integer) (p[2] as integer) (p[2] as integer) (p[3] as integer) (p[3] as integer) to:objfile
					)
					else if meshflags[1] == false and meshflags[2] == true then
					(
						vcface = (getVCFace mesh _curSel[j])
						format "f %//%/% %//%/% %//%/%\n" (p[1] as integer) (p[1] as integer) (vcface[1] as integer) (p[2] as integer) (p[2] as integer) (vcface[2] as integer) (p[3] as integer) (p[3] as integer) (vcface[3] as integer) to:objfile
					)
				)		
			)
			if InstanceMgr.Getinstances selection[n] &instances > 1 do -- if higher than 1, we know we have instanced nodes to handle
			(
				InstanceMgr.Getinstances selection[n] &instances /* don't forget that instances changes every loop */

				for curr_inst_count = 1 to instances.count do
				(
					current_instance = getNodeByName (instances[curr_inst_count].name)
					if(current_instance.name == selection[n].name) do continue
					
					format "instance %;\n" (n-1) to:scenefile
					format "pos % % %; \n" current_instance.pos[1] current_instance.pos[2] current_instance.pos[3] to:scenefile
					camRotEuler = quatToEuler2 current_instance.rotation.controller.value
					format "rot % % %; \n\n" camRotEuler.x camRotEuler.y camRotEuler.z to:scenefile
					currentname = instances[curr_inst_count].name
					append masterskiplist currentname
				)
			)
		)
		else format "skipped node %" n
	/*----------------END MESH EXPORT---------------*/
	
	fflush objfile
	fclose objfile
	) -- done with all nodes
	flush mtlfile
	close mtlfile
	flush scenefile
	close scenefile
	messagebox ("Done Exporting!")
	gc light:false
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