@tool
extends ResourceTablesDockEditor

var _stored_value : Texture2D


func try_edit_value(value, type, _property_hint) -> bool:
	if type != TYPE_OBJECT or !value is Texture:
		return false
	
	_stored_value = value
	$"HBoxContainer/TextureRect".texture = value
	return true


func _on_Button_pressed():
	var h_count = $"HBoxContainer/VBoxContainer/HBoxContainer/LineEdit".text.to_int()
	var v_count = $"HBoxContainer/VBoxContainer/HBoxContainer/LineEdit2".text.to_int()
	# No, Scene Unique Names can not be used in-editor (last time i checked)

	var folder_name := _stored_value.resource_path.get_basename()
	DirAccess.make_dir_recursive_absolute(folder_name)

	var tex_size := _stored_value.get_size()
	var tile_size := Vector2(tex_size.x / h_count, tex_size.y / v_count)
	var tile_array := []
	for j in v_count:
		for i in h_count:
			var tile := AtlasTexture.new()
			tile.region = Rect2(tile_size * Vector2(i, j), tile_size)
			tile.atlas = _stored_value
			tile_array.append(tile)
			tile.take_over_path(folder_name + "/" + folder_name.get_file() + "_" + str(j * h_count + i + 1) + ".tres")
			ResourceSaver.save(tile)

	tile_array.resize(sheet.get_edited_cells_values().size())
	sheet.set_edited_cells_values(tile_array)
	sheet.editor_plugin.get_editor_interface().get_resource_filesystem().scan()
		
