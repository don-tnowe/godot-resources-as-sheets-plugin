extends ResourceTablesCellEditor

const TablesPluginSettingsClass := preload("res://addons/resources_spreadsheet_view/settings_grid.gd")


func can_edit_value(value, type, property_hint, column_index) -> bool:
	return type == TYPE_PACKED_STRING_ARRAY or type == TYPE_ARRAY


func create_cell(caller : Control) -> Control:
	return load(CELL_SCENE_DIR + "array.tscn").instantiate()


func set_value(node : Control, value):
	var children := node.get_node("Box").get_children()
	node.custom_minimum_size.x = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "array_min_width")
	var colored = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "color_arrays")
	while children.size() < value.size():
		children.append(Label.new())
		node.get_node("Box").add_child(children[children.size() - 1])
	
	var column_hints = hint_strings_array[node.get_index() % hint_strings_array.size()]
	for i in children.size():
		if i >= value.size():
			children[i].visible = false

		else:
			children[i].visible = true
			_write_value_to_child(value[i], value[i], column_hints, children[i], colored)


func _write_value_to_child(value, key, hint_arr : PackedStringArray, child : Label, colored : bool):
	if value is Resource:
		value = _resource_to_string(value)

	child.text = str(value)
	child.self_modulate = (
		Color.WHITE
		if !colored else
		Color(str(key).hash()) + Color(0.25, 0.25, 0.25, 1.0)
	)


func _resource_to_string(res : Resource):
	return res.resource_name if res.resource_name != "" else res.resource_path.get_file()


func is_text():
	return false
