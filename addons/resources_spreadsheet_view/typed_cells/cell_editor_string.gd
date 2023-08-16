extends ResourceTablesCellEditor


func set_color(node : Control, color : Color):
	node.get_node("Back").modulate = color * 0.6 if !node.text.is_valid_float() else color
