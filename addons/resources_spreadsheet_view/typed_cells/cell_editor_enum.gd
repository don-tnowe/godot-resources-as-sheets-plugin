extends ResourceTablesCellEditor


func can_edit_value(value, type, property_hint, column_index) -> bool:
	return type == TYPE_INT and property_hint == PROPERTY_HINT_ENUM


func set_value(node : Control, value):
	if value == null:
		# Sometimes, when creating new property, becomes null
		value = 0

	var value_str : String
	var key_found := -1
	var hint_arr : Array = hint_strings_array[node.get_index() % hint_strings_array.size()]
	for i in hint_arr.size():
		var colon_found : int = hint_arr[i].rfind(":")
		if colon_found == -1:
			key_found = value
			break

		if hint_arr[i].substr(colon_found + 1).to_int() == value:
			key_found = i
			break

	if key_found != -1:
		value_str = hint_arr[key_found]

	else:
		value_str = "?:%s" % value

	node.text = value_str
	node.self_modulate = Color(node.text.hash()) + Color(0.25, 0.25, 0.25, 1.0)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func is_text():
	return false
