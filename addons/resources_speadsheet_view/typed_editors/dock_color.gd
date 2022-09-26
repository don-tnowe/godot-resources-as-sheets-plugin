tool
extends SheetsDockEditor

onready var _value_rect := $"EditColor/ColorProper/ColorRect"
onready var _color_picker_panel := $"EditColor/VSeparator6/Panel"
onready var _color_picker := $"EditColor/VSeparator6/Panel/MarginContainer/ColorPicker"
onready var _custom_value_edit := $"EditColor/CustomX/LineEdit"

var _stored_value := Color.white


func _ready():
	_connect_buttons($"EditColor/RGBGrid", 0, 0)
	_connect_buttons($"EditColor/RGBGrid", 5, 1)
	_connect_buttons($"EditColor/RGBGrid", 10, 2)
	_connect_buttons($"EditColor/HSVGrid", 0, 3)
	_connect_buttons($"EditColor/HSVGrid", 5, 4)
	_connect_buttons($"EditColor/HSVGrid", 10, 5)


func _connect_buttons(grid, start_index, property_bind):
	grid.get_child(start_index + 0).connect("pressed", self, "_increment_values_custom", [-1.0, property_bind])
	grid.get_child(start_index + 1).connect("pressed", self, "_increment_values", [-10.0, property_bind])
	grid.get_child(start_index + 3).connect("pressed", self, "_increment_values", [10.0, property_bind])
	grid.get_child(start_index + 4).connect("pressed", self, "_increment_values_custom", [1.0, property_bind])


func try_edit_value(value, type, property_hint) -> bool:
	_color_picker_panel.set_as_toplevel(false)
	if type != TYPE_COLOR:
		return false
	
	_set_stored_value(value)
	_color_picker_panel.visible = false
	return true


func _set_stored_value(v):
	_stored_value = v
	_color_picker.color = v
	_value_rect.color = v


func _increment_values(by : float, property : int):
	var cell_values = sheet.get_edited_cells_values()
	match property:
		0:
			_stored_value.r += by / 255.0
			for i in cell_values.size():
				cell_values[i].r += by / 255.0
				
		1:
			_stored_value.g += by / 255.0
			for i in cell_values.size():
				cell_values[i].g += by / 255.0
				
		2:
			_stored_value.b += by / 255.0
			for i in cell_values.size():
				cell_values[i].b += by / 255.0
				
		3:
			# Hue has 360 degrees and loops
			_stored_value.h += by / 360.0
			for i in cell_values.size():
				cell_values[i].h = fposmod(cell_values[i].h + by / 360.0, 1.0)
				
		4:
			_stored_value.s += by * 0.005
			for i in cell_values.size():
				cell_values[i].s += by * 0.005
				
		5:
			_stored_value.v += by * 0.005
			for i in cell_values.size():
				cell_values[i].v += by * 0.005

	_set_stored_value(_stored_value)
	sheet.set_edited_cells_values(cell_values)


func _increment_values_custom(multiplier : float, property : int):
	if property == 4 or property == 5:
		# Numbered buttons increment by 5 for Sat and Value, so hue is x0.5 effect. Negate it here
		multiplier *= 2.0
		
	_increment_values(float(_custom_value_edit.text) * multiplier, property)


func _on_Button_pressed():
	_color_picker_panel.visible = !_color_picker_panel.visible
	if _color_picker_panel.visible:
		_color_picker_panel.set_as_toplevel(true)
		_color_picker_panel.rect_global_position = (
			sheet.rect_global_position
			+ Vector2(0, sheet.rect_size.y - _color_picker_panel.rect_size.y)
			+ Vector2(16, -16)
		)
		_color_picker_panel.rect_global_position.y = clamp(
			_color_picker_panel.rect_global_position.y, 
			0, 
			sheet.editor_plugin.get_editor_interface().get_base_control().rect_size.y
		)
		_color_picker.color = _stored_value

	elif _color_picker.color != _stored_value:
		_set_stored_value(_color_picker.color)
		update_cell_values()


func _on_ColorPicker_gui_input(event : InputEvent):
	if event is InputEventMouseButton && !event.pressed:
		_set_stored_value(_color_picker.color)
		update_cell_values()


func update_cell_values():
	var values = sheet.get_edited_cells_values()
	for i in values.size():
		values[i] = _stored_value

	sheet.set_edited_cells_values(values)
