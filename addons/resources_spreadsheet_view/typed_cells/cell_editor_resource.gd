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
	if value == null:
		node.get_node("Box/Tex").visible = false
		node.get_node("Box/Label").text = "[empty]"
		node.editor_description = ""

	if !value is Resource: return
	
	node.editor_description = value.resource_path
	if value.resource_name == "":
		node.get_node("Box/Label").text = "[" + value.resource_path.get_file().get_basename() + "]"

	else:
		node.get_node("Box/Label").text = value.resource_name

	if value is Texture:
		node.get_node("Box/Tex").visible = true
		node.get_node("Box/Tex").texture = value

	else:
		node.get_node("Box/Tex").visible = false
		previewer.queue_resource_preview(value.resource_path, self, &"_on_preview_loaded", node)
		
	node.get_node("Box/Tex").custom_minimum_size = Vector2.ONE * ProjectSettings.get_setting(
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
