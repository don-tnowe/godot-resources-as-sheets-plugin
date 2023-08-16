@tool
extends EditorPlugin

var editor_view : Control
var undo_redo : EditorUndoRedoManager


func _enter_tree() -> void:
	editor_view = load(get_script().resource_path.get_base_dir() + "/editor_view.tscn").instantiate()
	editor_view.editor_interface = get_editor_interface()
	editor_view.editor_plugin = self
	undo_redo = get_undo_redo()
	get_editor_interface().get_editor_main_screen().add_child(editor_view)
	_make_visible(false)


func _exit_tree() -> void:
	if is_instance_valid(editor_view):
		editor_view.queue_free()


func _get_plugin_name():
	return "ResourceTables"


func _make_visible(visible):
	if is_instance_valid(editor_view):
		editor_view.visible = visible
		if visible:
			editor_view.display_folder(editor_view.current_path)


func _has_main_screen():
	return true


func _get_plugin_icon():
	# Until I add an actual icon, this'll do.
	return get_editor_interface().get_base_control().get_theme_icon("VisualShaderNodeComment", "EditorIcons")
