@tool
extends HBoxContainer

var editor_view : Control


func set_label(label : String):
	$"Button".text = TextEditingUtils.string_snake_to_naming_case(label)
	$"Button".tooltip_text = label + "\nClick to sort."


func _ready():
	$"Button".gui_input.connect(_on_main_gui_input)
	$"Button2".get_popup().id_pressed.connect(_on_list_id_pressed)


func _on_main_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var popup = $"Button2".get_popup()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			popup.visible = !popup.visible
			popup.position = get_global_mouse_position()

		else:
			popup.visible = false


func _on_list_id_pressed(id : int):
	if id == 0:
		editor_view.select_column(get_index())

	else:
		editor_view.hide_column(get_index())
