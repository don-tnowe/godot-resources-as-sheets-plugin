extends ResourceTablesCellEditor


func create_cell(caller : Control) -> Control:
	var cell_scene: Label = load(CELL_SCENE_DIR + "basic.tscn").instantiate()
	cell_scene.resized.connect(_resize_text.bind(cell_scene))
	return cell_scene

func _resize_text(cell: Label):
	if cell.text.length() <= 65:
		cell.autowrap_mode = TextServer.AUTOWRAP_OFF
	else:
		cell.autowrap_mode = TextServer.AUTOWRAP_WORD
		cell.custom_minimum_size.x = 350

func to_text(value) -> String:
	return str(value)


func from_text(text : String):
	return text


func set_color(node : Control, color : Color):
	node.get_node("Back").modulate = color * 0.6
