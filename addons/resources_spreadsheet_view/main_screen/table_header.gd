@tool
extends HBoxContainer

var manager : Control


func set_label(label : String):
	$"Button".text = label.capitalize()
	$"Button".tooltip_text = label + "\nClick to sort."


func _ready():
	$"Button".gui_input.connect(_on_main_gui_input)

	var menu_popup : PopupMenu = $"Button2".get_popup()
	menu_popup.id_pressed.connect(_on_list_id_pressed)
	menu_popup.add_item("Select All", 0)
	menu_popup.add_item("Hide", 1)
	menu_popup.add_item("Open Sub-Resources", 2)
	if !manager.editor_view.column_can_solo_open(get_index()):
		menu_popup.set_item_disabled(2, true)


func _on_main_gui_input(event : InputEvent):
	if event is InputEventMouseButton and event.pressed:
		var popup = $"Button2".get_popup()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			popup.visible = !popup.visible
			popup.size = Vector2.ZERO
			popup.position = Vector2i(get_global_mouse_position()) + get_viewport().position

		else:
			popup.visible = false


func _on_list_id_pressed(id : int):
	match id:
		0:
			manager.select_column(get_index())
		1:
			manager.hide_column(get_index())
		2:
			manager.editor_view.column_solo_open(get_index())
