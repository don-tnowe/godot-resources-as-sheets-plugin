extends "res://addons/resources_spreadsheet_view/typed_cells/cell_editor_array.gd"


func can_edit_value(value, type, property_hint, column_index) -> bool:
	return type == TYPE_DICTIONARY


func create_cell(caller : Control) -> Control:
	return load(CELL_SCENE_DIR + "array.tscn").instantiate()


func set_value(node : Control, value):
	var children = node.get_node("Box").get_children()
	node.custom_minimum_size.x = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "array_min_width")
	var colored = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "color_arrays")
	while children.size() < value.size():
		children.append(Label.new())
		node.get_node("Box").add_child(children[children.size() - 1])
	
	var column_hints = hint_strings_array[node.get_index() % hint_strings_array.size()]
	var values : Array = value.values()
	var keys : Array = value.keys()

	for i in children.size():
		if i >= values.size():
			children[i].visible = false

		else:
			children[i].visible = true
			if values[i] is Resource: values[i] = _resource_to_string(values[i])
			if keys[i] is Resource: keys[i] = _resource_to_string(keys[i])

			_write_value_to_child("%s ◆ %s" % [keys[i], values[i]], keys[i], column_hints, children[i], colored)


func is_text():
	return false
