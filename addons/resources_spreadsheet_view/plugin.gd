@tool
extends EditorPlugin

var editor_view : Control
var popup_plugin : EditorContextMenuPlugin
var undo_redo : EditorUndoRedoManager
var icon : Texture2D

func _enter_tree() -> void:
	var base_dir = get_script().resource_path.get_base_dir()
	editor_view = load(base_dir + "/editor_view.tscn").instantiate()
	editor_view.editor_interface = get_editor_interface()
	if editor_view.editor_interface == null:
		# 4.2: now a singleton
		editor_view.editor_interface = Engine.get_singleton("EditorInterface")

	undo_redo = get_undo_redo()

	editor_view.editor_plugin = self
	get_editor_interface().get_editor_main_screen().add_child(editor_view)

	popup_plugin = load(base_dir + "/editor_popup_plugin.gd").new();
	popup_plugin.editor_plugin = self
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, popup_plugin);
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
	# This variable has to be set here, as _get_plugin_icon is called before _enter_tree for some reason.
	icon = get_editor_interface().get_base_control().get_theme_icon("VisualShaderNodeComment", "EditorIcons")
	return icon
