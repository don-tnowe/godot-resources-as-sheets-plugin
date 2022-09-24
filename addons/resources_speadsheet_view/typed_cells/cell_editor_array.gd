extends CellEditor


func can_edit_value(value, type, property_hint) -> bool:
	return type == TYPE_STRING_ARRAY || type == TYPE_ARRAY


func create_cell(caller : Control) -> Control:
	return load(CELL_SCENE_DIR + "array.tscn").instance()


func set_value(node : Control, value):
	var children = node.get_node("Box").get_children()
	node.rect_min_size.x = ProjectSettings.get_setting(SettingsGrid.SETTING_PREFIX + "array_min_width")
	var colored = ProjectSettings.get_setting(SettingsGrid.SETTING_PREFIX + "color_arrays")
	while children.size() < value.size():
		children.append(Label.new())
		node.get_node("Box").add_child(children[children.size() - 1])

	for i in children.size():
		if i >= value.size():
			children[i].visible = false

		else:
			children[i].visible = true
			children[i].text = str(value[i])
			children[i].self_modulate = Color.white if !colored else Color(str(value[i]).hash()) + Color(0.25, 0.25, 0.25, 1.0)


func is_text():
	return false
