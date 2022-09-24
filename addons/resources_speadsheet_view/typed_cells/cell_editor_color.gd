extends CellEditor

var _cached_color := Color.white


func create_cell(caller : Control) -> Control:
	var node = load(CELL_SCENE_DIR + "basic.tscn").instance()
	var color = ColorRect.new()
	node.align = Label.ALIGN_RIGHT
	node.rect_min_size.x = 56
	node.add_child(color)
	color.name = "Color"
	color.anchor_bottom = 1.0
	color.rect_size = Vector2(8, 0)
	return node


func can_edit_value(value, type, property_hint) -> bool:
	return type == TYPE_COLOR


func set_value(node : Control, value):
	if value is String:
		node.text = TextEditingUtils.show_non_typing(str(value))

	else:
		node.text = value.to_html(true)
		_cached_color = value

	node.get_node("Color").color = value
