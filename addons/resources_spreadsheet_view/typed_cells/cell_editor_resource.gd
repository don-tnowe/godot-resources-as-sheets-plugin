extends ResourceTablesCellEditor

const TablesPluginSettingsClass := preload("res://addons/resources_spreadsheet_view/settings_grid.gd")

var previewer : EditorResourcePreview


func can_edit_value(value, type, property_hint, column_index) -> bool:
	return type == TYPE_OBJECT


func create_cell(caller : Control) -> Control:
	if previewer == null:
		previewer = caller.editor_plugin.get_editor_interface().get_resource_previewer()

	var node = load(CELL_SCENE_DIR + "resource.tscn").instantiate()
	return node


func set_value(node : Control, value):
	var preview_node := node.get_node("Box/Tex")
	var label_node := node.get_node("Box/Label")
	if value == null:
		preview_node.visible = false
		label_node.text = "[empty]"
		node.editor_description = ""

	if !value is Resource: return
	
	node.editor_description = value.resource_path
	label_node.text = _resource_to_string(value, ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "resource_cell_label_mode", 0))

	if value is Texture:
		preview_node.visible = true
		preview_node.texture = value

	else:
		preview_node.visible = false
		previewer.queue_resource_preview(value.resource_path, self, &"_on_preview_loaded", node)
		
	preview_node.custom_minimum_size = Vector2.ONE * ProjectSettings.get_setting(
		TablesPluginSettingsClass.PREFIX + "resource_preview_size"
	)


func set_color(node : Control, color : Color):
	node.get_node("Back").modulate = color * 0.6 if node.editor_description == "" else color


func is_text():
	return false


func _on_preview_loaded(path : String, preview : Texture, thumbnail_preview : Texture, node):
	# Abort if the node has been deleted since.
	if is_instance_valid(node):
		node.get_node("Box/Tex").visible = true
		node.get_node("Box/Tex").texture = preview


static func _resource_to_string(res : Resource, cell_label_mode : int):
	var prefix := ""
	if cell_label_mode != 2:
		if res.has_method(&"_to_string"):
			prefix = res._to_string() + "\n"

		elif res.has_method(&"ToString"):
			prefix = res.ToString() + "\n"

	if cell_label_mode == 1 && !prefix.is_empty():
		return prefix.trim_suffix("\n")

	return prefix + (res.resource_name if res.resource_name != "" else "[%s]" % res.resource_path.get_file())
