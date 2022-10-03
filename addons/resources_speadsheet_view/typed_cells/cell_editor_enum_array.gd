extends CellEditorArray


func can_edit_value(value, type, property_hint) -> bool:
	return (type == TYPE_INT_ARRAY or type == TYPE_ARRAY) and property_hint == 26


func _write_value_to_child(value, hint_arr : PoolStringArray, child : Label, colored : bool):
	if value == 0:
		# Enum array hints have "2/3:" before list.
		var found := hint_arr[0].find(":") + 1
		._write_value_to_child(hint_arr[0].substr(hint_arr[0].find(":") + 1), hint_arr, child, colored)

	else:
		._write_value_to_child(hint_arr[value], hint_arr, child, colored)
