extends CellEditor

var _cached_color := Color.white


func can_edit_value(value, type, property_hint) -> bool:
	return type == TYPE_COLOR


func get_value(node : Control):
	var val = TextEditingUtils.revert_non_typing(node.text)
	if val.length() == 3 || val.length() == 6 || val.length() == 8:
		return Color(val)
		
	else:
		return _cached_color


func set_value(node : Control, value):
	if value is String:
		node.text = TextEditingUtils.show_non_typing(str(value))

	else:
		node.text = value.to_html(true)
		_cached_color = value
