extends "res://addons/resources_spreadsheet_view/typed_cells/cell_editor_array.gd"


func can_edit_value(value, type, property_hint, column_index) -> bool:
	if (
		type != TYPE_PACKED_INT32_ARRAY
		and type != TYPE_PACKED_INT64_ARRAY
		and type != TYPE_ARRAY
	) or property_hint != PROPERTY_HINT_TYPE_STRING:
		return false
	
	return hint_strings_array[column_index][0].begins_with("2/2:")


func _write_value_to_child(value, key, hint_arr : PackedStringArray, child : Label, colored : bool):
	var value_str : String
	var key_found := -1
	for i in hint_arr.size():
		var colon_found := hint_arr[i].rfind(":")
		if colon_found == -1:
			key_found = value
			break

		if hint_arr[i].substr(colon_found + 1).to_int() == value:
			key_found = i
			break

	if key_found == 0:
		# Enum array hints have "2/3:" before list.
		var found := hint_arr[0].find(":") + 1
		value_str = hint_arr[0].substr(hint_arr[0].find(":") + 1)

	elif key_found != -1:
		value_str = hint_arr[key_found]

	else:
		value_str = "?:%s" % value

	super(value_str, value_str, hint_arr, child, colored)
