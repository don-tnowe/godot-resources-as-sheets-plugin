extends "res://addons/resources_spreadsheet_view/typed_cells/cell_editor_array.gd"


func can_edit_value(value, type, property_hint, column_index) -> bool:
	return type == TYPE_DICTIONARY


func create_cell(caller : Control) -> Control:
	return load(CELL_SCENE_DIR + "array.tscn").instantiate()


func set_value(node : Control, value):
	if value.size() == 0:
		return

	var children := node.get_node("Box").get_children()
	node.custom_minimum_size.x = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "array_min_width")
	var color_tint : float = 0.01 * ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "array_color_tint", 100.0)
	var cell_label_mode : int = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "resource_cell_label_mode", 0)
	while children.size() < value.size():
		var new_label = Label.new()
		children.append(new_label)
		node.get_node("Box").add_child(new_label)
	
	var column_hints : PackedStringArray = hint_strings_array[node.get_index() % hint_strings_array.size()]
	var values : Array = value.values()
	var keys : Array = value.keys()

	if values.size() >= 2 && (values[0] is int || values[1] is int):
		# When a value is an enum, the dictionary is always types, so all keys/values are same type.
		for x in column_hints:
			if x.begins_with("2/2:") || x.find("2/2:") != -1:
				set_value_enum(node, value, children, keys, values, cell_label_mode, column_hints, color_tint)
				return

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


func set_value_enum(node : Control, value, children : Array[Node], keys : Array, values : Array, cell_label_mode : int, column_hints : PackedStringArray, color_tint : float) -> void:
	var key_enum_values : Dictionary[int, String] = {}
	var value_enum_values : Dictionary[int, String] = {}
	var parse_phase := 0
	for x in column_hints:
		var found_semicolon := x.rfind(";")
		if parse_phase == 0 && x.begins_with("2/2:"):
			var split := x.split(":")
			parse_phase = 1
			key_enum_values[split[-1].to_int()] = "%s:%s" % [split[-2], split[-1]]

		elif parse_phase == 1 && found_semicolon != -1:
			if x.find("2/2:") == -1:
				var split := x.left(found_semicolon).split(":")
				key_enum_values[split[-1].to_int()] = "%s:%s" % [split[-2], split[-1]]
				break

			else:
				var split := x.split(":")
				if parse_phase == 1:
					key_enum_values[split[0].to_int()] = "%s:%s" % [split[0], split[1].left(found_semicolon - split[0].length() - 1)]

				parse_phase = 2
				value_enum_values[split[-1].to_int()] = "%s:%s" % [split[-2], split[-1]]

		elif parse_phase == 1:
			var found := x.find(":")
			key_enum_values[x.substr(found + 1).to_int()] = x

		elif parse_phase == 2:
			var found := x.find(":")
			value_enum_values[x.substr(found + 1).to_int()] = x

	for i in children.size():
		if i >= values.size():
			children[i].visible = false

		else:
			children[i].visible = true
			var current_value = value_enum_values.get(values[i], values[i])
			var current_key = key_enum_values.get(keys[i], keys[i])
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
