@tool
extends EditorPlugin

const EDITOR_VIEW = preload("uid://5pic6fxx6et3")

var editor_view
var undo_redo : EditorUndoRedoManager


func _enter_tree() -> void:
	editor_view = EDITOR_VIEW.instantiate()
	editor_view.editor_interface =  Engine.get_singleton("EditorInterface")
		
	editor_view.editor_plugin = self
	undo_redo = get_undo_redo()
	editor_view.editor_interface.get_editor_main_screen().add_child(editor_view)
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
	return Engine.get_singleton("EditorInterface").get_editor_theme().get_icon("VisualShaderNodeComment", "EditorIcons")
