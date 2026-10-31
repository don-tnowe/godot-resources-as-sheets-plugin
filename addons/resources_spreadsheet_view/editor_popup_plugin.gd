@tool
extends EditorContextMenuPlugin

var editor_plugin : EditorPlugin

func item_pressed(paths: PackedStringArray):
    editor_plugin.editor_view.display_folder(paths[0])
    editor_plugin.get_editor_interface().set_main_screen_editor("ResourceTables")

func _popup_menu(paths: PackedStringArray):
    if paths.size() > 1 || !paths[0].ends_with("/"):
        return
    var path : String = paths[0]
    add_context_menu_item("Open in ResourceTables view", item_pressed, editor_plugin.icon)
