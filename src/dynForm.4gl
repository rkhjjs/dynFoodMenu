IMPORT FGL menuData

CONSTANT C_WIDTH=20

PUBLIC TYPE dynForm RECORD
	inpFields DYNAMIC ARRAY OF RECORD
		l_fldName STRING,
		l_fldType STRING
	END RECORD,
	no_of_flds SMALLINT,
	treeData DYNAMIC ARRAY OF menuRecord
END RECORD

--------------------------------------------------------------------------------------------------------------
-- Generate the screen form and recordView.
FUNCTION (this dynForm) buildForm( l_titl STRING, l_styl STRING ) RETURNS ()
	DEFINE l_f, l_w, l_vb, l_grid, l_group, l_sgroup, l_cont om.DomNode
	DEFINE l_fldnam, l_desc STRING
	DEFINE id,y,l_items SMALLINT
-- Create and setup Form / Window
	LET l_f = ui.Window.getCurrent().createForm("Menu").getNode()
	CALL l_f.setAttribute("text",l_titl)
	CALL l_f.setAttribute("style",l_styl)
	LET l_w = l_f.getParent()
	CALL l_w.setAttribute("text",l_titl)
	CALL l_w.setAttribute("style",l_styl)

-- Create the content of the form.
	LET l_vb = l_f.createChild("VBox")
	LET l_grid = l_vb.createChild("Grid")
	CALL l_grid.setAttribute("width",C_WIDTH+6)
	CALL l_grid.setAttribute("height",1)

	CALL this.inpFields.clear()
	LET this.no_of_flds = 0
	FOR id = 1 TO this.treeData.getLength()
		LET l_fldnam = this.treeData[id].field CLIPPED
		LET l_desc = this.treeData[id].description CLIPPED
		DISPLAY  this.treeData[id].type[1,2],":",l_fldnam,":",IIF(this.treeData[id].hidden,"T","F"),":",l_desc,":",IIF(l_sgroup IS NULL,"G","SG")
		IF this.treeData[id].hidden THEN CONTINUE FOR END IF
		CASE this.treeData[id].type
			WHEN "Type"
				CALL this.addField(id, 1, 1, l_grid, "",l_desc ,"Label", C_WIDTH)
			WHEN "Group"
				IF l_cont IS NOT NULL THEN -- set height for previous grid
					CALL l_cont.setAttribute("height",l_items)
				END IF
				LET l_group = this.addGroup(id, l_vb, l_desc)
				LET l_cont = l_group
			WHEN "Subgroup"
				IF l_cont IS NOT NULL AND l_items > 0 THEN -- set height for previous grid
					CALL l_cont.setAttribute("height",l_items)
				END IF
				IF this.treeData[id].visible THEN
					IF l_group.getTagName() = "Group" THEN
						LET l_group = l_group.createChild("VBox")
					END IF
					LET l_sgroup = this.addGroup(id, l_group, l_desc)
					LET l_cont = l_sgroup
				END IF
			WHEN "Item"
				IF l_cont.getTagName() = "Group" THEN
					LET l_cont = l_cont.createChild("Grid")
					CALL l_cont.setAttribute("width",C_WIDTH+6)
					CALL l_cont.setAttribute("height",1)
					LET l_items = 0
				END IF
				LET l_items = l_items + 1
				IF this.treeData[id].maxval = 1 THEN
					CALL this.addField(id, l_items, 1, l_cont, l_fldnam, l_desc,"CheckBox", C_WIDTH)
				ELSE
					CALL this.addField(id, l_items, 1, l_cont, l_fldnam, l_desc,"SpinEdit", 3)
					CALL this.addField(id, l_items, 5, l_cont, "", l_desc,"Label", C_WIDTH)
				END IF
				IF this.treeData[id].option_name IS NOT NULL THEN
					CALL this.addField(id, l_items, 15,l_cont, l_fldnam||"o1", this.treeData[id].option_name,"CheckBox", C_WIDTH)
				END IF
		END CASE
	END FOR
-- Create screen record
	LET l_grid = l_f.createChild("RecordView")
	CALL l_grid.setAttribute("tabName","formonly")
	FOR id = 1 TO this.inpFields.getLength()
		LET l_group = l_grid.createChild("Link")
		LET y = this.inpFields[id].l_fldName.getIndexOf(".",1)
		CALL l_group.setAttribute("colName",this.inpFields[id].l_fldName.subString(y+1,this.inpFields[id].l_fldName.getLength()))
		CALL l_group.setAttribute("fieldIdRef",id)
	END FOR
	CALL ui.Interface.refresh()
	CALL l_f.writeXml("generated.42f") -- for debug only!
END FUNCTION
--------------------------------------------------------------------------------------------------------------
PRIVATE FUNCTION (this dynForm) addGroup(id SMALLINT, l_n om.DomNode, l_desc STRING) RETURNS (om.DomNode)
	DEFINE l_group om.DomNode
	DEFINE l_nam STRING
	LET l_group = l_n.createChild("Group")
	LET l_nam = SFMT("%1_%2_%3",DOWNSHIFT(this.treeData[id].id CLIPPED), this.treeData[id].t_pid, this.treeData[id].t_id )
	CALL l_group.setAttribute("name",  l_nam)
	CALL l_group.setAttribute("text", l_desc)
	RETURN l_group
END FUNCTION
--------------------------------------------------------------------------------------------------------------
PRIVATE FUNCTION (this dynForm) addField(id SMALLINT, x SMALLINT, y SMALLINT, l_n om.DomNode, l_nam STRING, l_desc STRING, l_wdg STRING, l_width SMALLINT) RETURNS ()
	DEFINE l_ff, l_w om.DomNode
	DEFINE z SMALLINT
	DEFINE l_typ STRING
	IF l_nam IS NOT NULL THEN
		LET l_ff = l_n.createChild("FormField")
		LET z = l_nam.getIndexOf(".",1)
		CALL l_ff.setAttribute("name", l_nam)
		CALL l_ff.setAttribute("colName",l_nam.subString(z+1, l_nam.getLength()))
		CASE l_wdg
			WHEN "CheckBox" LET l_typ = "BOOLEAN"
			WHEN "SpinEdit" LET l_typ = "SMALLINT"
		END CASE
		LET this.no_of_flds = this.no_of_flds + 1
		LET this.inpFields[ this.no_of_flds ].l_fldName = l_nam
		LET this.inpFields[ this.no_of_flds ].l_fldType = l_typ
		CALL l_ff.setAttribute("fieldId", this.no_of_flds)
		CALL l_ff.setAttribute("sqlTabName", "formonly")
		CALL l_ff.setAttribute("tabIndex", this.no_of_flds)
		CALL l_ff.setAttribute("varType", l_typ)
		CALL l_ff.setAttribute("notNull",1)
		CALL l_ff.setAttribute("required",1)
		CALL l_ff.setAttribute("defaultValue",0)
		CALL l_ff.setAttribute("value",0)
		LET l_w = l_ff.createChild(l_wdg)
	ELSE
		LET l_w = l_n.createChild(l_wdg)
	END IF
	IF l_width > l_desc.getLength() AND l_desc.getLength() > 1 THEN LET l_width = l_desc.getLength() END IF
	IF l_wdg != "Label" THEN
		CALL l_w.setAttribute("width",l_width)
	END IF
	CALL l_w.setAttribute("text", l_desc)
	CALL l_w.setAttribute("posY", x)
	CALL l_w.setAttribute("posX", y)
	CALL l_w.setAttribute("gridWidth",l_width)
	IF l_wdg = "SpinEdit" THEN
		CALL l_w.setAttribute("valueMin",this.treeData[id].minval)
		CALL l_w.setAttribute("valueMax",this.treeData[id].maxval)
	END IF
END FUNCTION