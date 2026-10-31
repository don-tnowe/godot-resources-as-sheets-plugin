@tool
extends EditorPlugin

const EDITOR_VIEW = preload("uid://5pic6fxx6et3")

var editor_view
var popup_plugin : EditorContextMenuPlugin
var undo_redo : EditorUndoRedoManager
var icon : Texture2D

func _enter_tree() -> void:
	var base_dir = get_script().resource_path.get_base_dir()
	editor_view = EDITOR_VIEW.instantiate()
	editor_view.editor_interface = Engine.get_singleton("EditorInterface")
	editor_view.editor_plugin = self
	editor_view.editor_interface.get_editor_main_screen().add_child(editor_view)

	popup_plugin = load(base_dir + "/editor_popup_plugin.gd").new()
	popup_plugin.editor_plugin = self
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, popup_plugin)

	_make_visible(false)


func _exit_tree() -> void:
	remove_context_menu_plugin(popup_plugin)
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
	# This variable has to be set here, as _get_plugin_icon is called before _enter_tree by Godot.
	icon = Engine.get_singleton("EditorInterface").get_editor_theme().get_icon("VisualShaderNodeComment", "EditorIcons")
	return icon
