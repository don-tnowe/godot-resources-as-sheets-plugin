tool
extends HBoxContainer

var editor_view : Control


func set_label(label : String):
	$"Button".text = TextEditingUtils.string_snake_to_naming_case(label)
	$"Button".hint_tooltip = label + "\nClick to sort."


func _ready():
	$"Button".connect("gui_input", self, "_on_main_gui_input")
	$"Button2".get_popup().connect("id_pressed", self, "_on_list_id_pressed")


func _on_main_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var popup = $"Button2".get_popup()
		if event.button_index == BUTTON_RIGHT:
			popup.visible = !popup.visible
			popup.rect_position = get_global_mouse_position()

		else:
			popup.visible = false


func _on_list_id_pressed(id : int):
	if id == 0:
		editor_view.select_column(get_position_in_parent())

	else:
		editor_view.hide_column(get_position_in_parent())
