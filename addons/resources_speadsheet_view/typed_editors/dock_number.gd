tool
extends SheetsDockEditor

onready var number_panel = $"HBoxContainer/CustomX/HBoxContainer/NumberPanel"

var mouse_down := false


func can_edit_value(value, type, property_hint) -> bool:
  return type == TYPE_REAL or type == TYPE_INT


func _on_NumberPanel_gui_input(event):
  if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
    if event.pressed:
      Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
      mouse_down = true

    else:
      Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
      if mouse_down:
        Input.warp_mouse_position(number_panel.rect_global_position + number_panel.rect_size * 0.5)
        
      mouse_down = false

  if mouse_down and event is InputEventMouseMotion:
    number_panel.get_child(0).text = str(float(number_panel.get_child(0).text) + event.relative.x * 0.01)
