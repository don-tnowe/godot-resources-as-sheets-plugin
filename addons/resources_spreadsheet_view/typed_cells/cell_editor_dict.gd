extends "res://addons/resources_spreadsheet_view/typed_cells/cell_editor_array.gd"


func can_edit_value(value, type, property_hint, column_index) -> bool:
	return type == TYPE_DICTIONARY


func create_cell(caller : Control) -> Control:
	return load(CELL_SCENE_DIR + "array.tscn").instantiate()


func set_value(node : Control, value):
	var children := node.get_node("Box").get_children()
	node.custom_minimum_size.x = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "array_min_width")
	var color_tint : float = 0.01 * ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "array_color_tint", 100.0)
	var cell_label_mode : int = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "resource_cell_label_mode", 0)
	while children.size() < value.size():
		children.append(Label.new())
		node.get_node("Box").add_child(children[children.size() - 1])
	
	var column_hints : PackedStringArray = hint_strings_array[node.get_index() % hint_strings_array.size()]
	var values : Array = value.values()
	var keys : Array = value.keys()

	for i in children.size():
		if i >= values.size():
			children[i].visible = false

		else:
			children[i].visible = true
			var current_value = values[i]
			var current_key = keys[i]
			if current_value is Resource:
				current_value = _resource_to_string(current_value, cell_label_mode)

			if current_key is Resource:
				current_key = _resource_to_string(current_key, cell_label_mode)

			_write_value_to_child("%s ◆ %s" % [current_key, current_value], current_key, column_hints, children[i], color_tint, cell_label_mode)


func is_text():
	return false


func to_text(value) -> String:
	return var_to_str(value).replace("\n", " ")


func from_text(text : String):
	return str_to_var(text)
