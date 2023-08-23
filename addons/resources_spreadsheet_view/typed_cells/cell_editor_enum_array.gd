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
	if value == 0:
		# Enum array hints have "2/3:" before list.
		var found := hint_arr[0].find(":") + 1
		value_str = hint_arr[0].substr(hint_arr[0].find(":") + 1)

	elif value < hint_arr.size():
		value_str = hint_arr[value]

	else:
		value_str = "?:%s" % value

	super(value_str, value_str, hint_arr, child, colored)
