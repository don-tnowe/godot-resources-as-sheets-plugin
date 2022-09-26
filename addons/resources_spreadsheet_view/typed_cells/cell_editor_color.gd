extends CellEditor

var _cached_color := Color.WHITE


func create_cell(caller : Control) -> Control:
	var node : Label = load(CELL_SCENE_DIR + "basic.tscn").instantiate()
	var color := ColorRect.new()
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	node.custom_minimum_size.x = 56
	node.add_child(color)
	color.name = "Color"
	call_deferred("_resize_color_rect", color)
	return node


func _resize_color_rect(rect : ColorRect):
	rect.size = Vector2(8, 0)
	rect.anchors_preset = Control.PRESET_LEFT_WIDE
	await rect.get_tree().process_frame
	rect.size.x = 8


func can_edit_value(value, type, property_hint, property_hint_string) -> bool:
	return type == TYPE_COLOR


func set_value(node : Control, value):
	if value is String:
		node.text = TextEditingUtils.show_non_typing(str(value))

	else:
		node.text = value.to_html(true)
		_cached_color = value

	node.get_node("Color").color = value
