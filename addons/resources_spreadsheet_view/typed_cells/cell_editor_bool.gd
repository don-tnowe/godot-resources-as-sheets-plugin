extends ResourceTablesCellEditor


func can_edit_value(value, type, property_hint, column_index) -> bool:
	return type == TYPE_BOOL


func set_value(node : Control, value):
	if value is bool:
		_set_value_internal(node, value)

	else:
		_set_value_internal(node, node.text.begins_with("O"))


func _set_value_internal(node, value):
	node.text = "ON" if value else "off"
	node.self_modulate.a = 1.0 if value else 0.2


func text_update_on_edit():
	return true


func to_text(value) -> String:
	return "ON" if value else "off"


func from_text(text : String):
	if text.begins_with("O"):
		return text == "ON"

	else:
		return text != "off"
