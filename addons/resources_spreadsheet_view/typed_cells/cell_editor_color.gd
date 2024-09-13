extends ResourceTablesCellEditor

var _cached_color := Color.WHITE


func create_cell(caller : Control) -> Control:
	var node : Label = load(CELL_SCENE_DIR + "basic.tscn").instantiate()
	var color := ColorRect.new()
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	node.custom_minimum_size.x = 56
	node.add_child(color)
	color.name = "Color"
	_resize_color_rect.call_deferred(color)
	return node


func _resize_color_rect(rect):
	if !is_instance_valid(rect): return  # Table refreshed twice, probably? Either way, this fix is easier
	rect.size = Vector2(8, 0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE, Control.PRESET_MODE_KEEP_WIDTH)


func can_edit_value(value, type, property_hint, property_hint_string) -> bool:
	return type == TYPE_COLOR


func set_value(node : Control, value):
	if value is String:
		node.text = TextEditingUtilsClass.show_non_typing(str(value))

	else:
		node.text = value.to_html(true)
		_cached_color = value

	node.get_node("Color").color = value


func to_text(value) -> String:
	return value.to_html()


func from_text(text : String):
	return Color.from_string(text, Color.BLACK)
