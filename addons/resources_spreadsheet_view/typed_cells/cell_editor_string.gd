extends ResourceTablesCellEditor


func to_text(value) -> String:
	return str(value)


func from_text(text : String):
	return text


func set_color(node : Control, color : Color):
	node.get_node("Back").modulate = color * 0.6
