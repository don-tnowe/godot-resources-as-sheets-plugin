@tool
extends HBoxContainer

var manager : Control


func set_label(label : String):
	$"Button".text = label.capitalize()
	$"Button".tooltip_text = label + "\nClick to sort."


func _ready():
	$"Button".gui_input.connect(_on_main_gui_input)
	$"Button2".get_popup().id_pressed.connect(_on_list_id_pressed)


func _on_main_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var popup = $"Button2".get_popup()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			popup.visible = !popup.visible
			popup.size = Vector2.ZERO
			popup.position = Vector2i(get_global_mouse_position()) + get_viewport().position

		else:
			popup.visible = false


func _on_list_id_pressed(id : int):
	if id == 0:
		manager.select_column(get_index())

	else:
		manager.hide_column(get_index())
