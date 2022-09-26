extends CellEditorArray


func can_edit_value(value, type, property_hint, column_index) -> bool:
	if (type != TYPE_PACKED_INT32_ARRAY and type != TYPE_PACKED_INT64_ARRAY and type != TYPE_ARRAY) or property_hint != 25:
		return false
	
	return hint_strings_array[column_index][0].begins_with("2/2:")


func _write_value_to_child(value, hint_arr : PackedStringArray, child : Label, colored : bool):
	if value == 0:
		# Enum array hints have "2/3:" before list.
		var found := hint_arr[0].find(":") + 1
		super._write_value_to_child(hint_arr[0].substr(hint_arr[0].find(":") + 1), hint_arr, child, colored)

	else:
		super._write_value_to_child(hint_arr[value], hint_arr, child, colored)
