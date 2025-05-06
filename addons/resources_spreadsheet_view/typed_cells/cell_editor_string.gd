extends ResourceTablesCellEditor


func create_cell(caller : Control) -> Control:
	var cell_scene: Label = load(CELL_SCENE_DIR + "basic.tscn").instantiate()
	cell_scene.resized.connect(_resize_text.bind(cell_scene))
	return cell_scene

func _resize_text(cell: Label):
	var string_size = cell.get_theme_font("font").get_string_size(cell.text, HORIZONTAL_ALIGNMENT_LEFT, -1, cell.get_theme_font_size("normal_font_size"))
	var string_width = string_size.x
	var max_column_width = DisplayServer.window_get_size().x / 4
	if string_width >= max_column_width:
		cell.autowrap_mode = TextServer.AUTOWRAP_WORD
		cell.custom_minimum_size.x = max_column_width
	else:
		cell.autowrap_mode = TextServer.AUTOWRAP_OFF
		cell.custom_minimum_size.x = 24

func to_text(value) -> String:
	return str(value)


func from_text(text : String):
	return text


func set_color(node : Control, color : Color):
	node.get_node("Back").modulate = color * 0.6
