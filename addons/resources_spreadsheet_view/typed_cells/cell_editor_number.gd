extends ResourceTablesCellEditor


func can_edit_value(value, type, property_hint, column_index) -> bool:
	return type == TYPE_FLOAT or type == TYPE_INT


func to_text(value) -> String:
	return str(value)


func from_text(text : String):
	return text.to_float()
