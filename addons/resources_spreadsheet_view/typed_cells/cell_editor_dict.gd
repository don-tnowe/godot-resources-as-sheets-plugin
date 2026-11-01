extends "res://addons/resources_spreadsheet_view/typed_cells/cell_editor_array.gd"


func can_edit_value(value, type, property_hint, column_index) -> bool:
	return type == TYPE_DICTIONARY


func create_cell(caller : Control) -> Control:
	return load(CELL_SCENE_DIR + "array.tscn").instantiate()


func set_value(node : Control, value):
	var parent = node.get_node("Box")
	var children := parent.get_children()
	node.custom_minimum_size.x = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "array_min_width")
	var cell_label_mode : int = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "resource_cell_label_mode", 0)
	while children.size() < value.size():
		var new_label = Label.new()
		children.append(new_label)
		parent.add_child(new_label)

	while children.size() > value.size():
		var child = parent.get_child(parent.get_child_count() - 1)		
		child.get_parent().remove_child(child)
		child.queue_free()
		children.erase(child)
	
	var column_hints : PackedStringArray = hint_strings_array[node.get_index() % hint_strings_array.size()]
	var values : Array = value.values()
	var keys : Array = value.keys()

	if (values.size() > 0 and values[0] is int) or (keys.size() > 0 and keys[0] is int):
		# If there's an int, the dict could be static-typed as enum.
		for x in column_hints:
			if x.begins_with("2/2:") or x.find("2/2:") != -1:
				set_value_enum(node, value, children, keys, values, cell_label_mode, column_hints)
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

			_write_value_to_child("%s ◆ %s" % [current_key, current_value], current_key, column_hints, children[i], cell_label_mode)


func set_value_enum(node : Control, value, children : Array[Node], keys : Array, values : Array, cell_label_mode : int, column_hints : PackedStringArray) -> void:
	# The hint is "key_type/key_hint:key_hint_string;value_type/value_hint:value_hint_string",
	# and column_hints holds it split by commas, so the halves are joined back first.
	var hint_halves := ",".join(column_hints).split(";")
	var key_enum_values := _parse_enum_hint(hint_halves[0])
	var value_enum_values := _parse_enum_hint(hint_halves[1] if hint_halves.size() > 1 else "")

	for i in children.size():
		if i >= values.size():
			children[i].visible = false

		else:
			children[i].visible = true
			var current_value = value_enum_values.get(values[i], values[i]) if values[i] is int else values[i]
			var current_key = key_enum_values.get(keys[i], keys[i]) if keys[i] is int else keys[i]
			if current_value is Resource:
				current_value = _resource_to_string(current_value, cell_label_mode)

			if current_key is Resource:
				current_key = _resource_to_string(current_key, cell_label_mode)

			_write_value_to_child("%s ◆ %s" % [current_key, current_value], current_key, column_hints, children[i], cell_label_mode)


# Turns one half of a typed Dictionary hint, like "2/2:Zero:0,One:1,Two:2", into {0: "Zero:0", 1: "One:1", 2: "Two:2"}.
# Returns an empty Dictionary if that half is not an int enum.
func _parse_enum_hint(hint : String) -> Dictionary[int, String]:
	var result : Dictionary[int, String] = {}
	if !hint.begins_with("2/2:"):
		return result

	var next_value := 0
	for x in hint.substr(4).split(","):
		var found := x.rfind(":")
		var name := x
		if found != -1:
			name = x.left(found)
			next_value = x.substr(found + 1).to_int()

		result[next_value] = "%s:%s" % [name, next_value]
		next_value += 1

	return result


func is_text():
	return false


func to_text(value) -> String:
	return var_to_str(value).replace("\n", " ")


func from_text(text : String):
	return str_to_var(text)
