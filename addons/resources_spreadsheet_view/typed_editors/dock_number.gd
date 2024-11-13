@tool
extends ResourceTablesDockEditor

@onready var _value_label := $"HBoxContainer/HBoxContainer/NumberPanel/Label"
@onready var _button_grid := $"HBoxContainer/HBoxContainer/GridContainer"
@onready var _button_grid_small := $"HBoxContainer/HBoxContainer/GridContainerSmall"
@onready var _sequence_gen_inputs := $"HBoxContainer/CustomX2/HBoxContainer"
@onready var _custom_value_edit := $"HBoxContainer/CustomX/Box/LineEdit"

var _stored_value = 0
var _stored_value_is_int := false

var _mouse_drag_increment := 0.0
var _mouse_down := false

var _resize_height_small := 0.0
var _resize_expanded := true


func _ready():
	super._ready()
	_button_grid.get_child(0).pressed.connect(_increment_values.bind(+0.1))
	_button_grid.get_child(1).pressed.connect(_increment_values.bind(+1))
	_button_grid.get_child(2).pressed.connect(_increment_values.bind(+10))
	_button_grid.get_child(3).pressed.connect(_increment_values.bind(+100))
	_button_grid.get_child(4).pressed.connect(_increment_values_custom.bind(true, false))
	_button_grid.get_child(5).pressed.connect(_increment_values_custom.bind(true, true))

	_button_grid.get_child(6).pressed.connect(_increment_values.bind(-0.1))
	_button_grid.get_child(7).pressed.connect(_increment_values.bind(-1))
	_button_grid.get_child(8).pressed.connect(_increment_values.bind(-10))
	_button_grid.get_child(9).pressed.connect(_increment_values.bind(-100))
	_button_grid.get_child(10).pressed.connect(_increment_values_custom.bind(false, false))
	_button_grid.get_child(11).pressed.connect(_increment_values_custom.bind(false, true))

	_button_grid_small.get_child(1).pressed.connect(_increment_values_custom.bind(false, true))
	_button_grid_small.get_child(2).pressed.connect(_increment_values_custom.bind(false, false))
	_button_grid_small.get_child(3).pressed.connect(_increment_values.bind(-1))
	_button_grid_small.get_child(4).pressed.connect(_increment_values.bind(+1))
	_button_grid_small.get_child(5).pressed.connect(_increment_values_custom.bind(true, false))
	_button_grid_small.get_child(6).pressed.connect(_increment_values_custom.bind(true, true))

	_resize_height_small = get_child(1).get_minimum_size().y


func try_edit_value(value, type, property_hint) -> bool:
	if type != TYPE_FLOAT and type != TYPE_INT:
		return false
	
	_stored_value = value
	_value_label.text = str(value)
	
	_stored_value_is_int = type != TYPE_FLOAT
	_button_grid.columns = 5 if _stored_value_is_int else 6
	_button_grid.get_child(0).visible = !_stored_value_is_int
	_button_grid.get_child(6).visible = !_stored_value_is_int

	return true


func resize_drag(to_height : float):
	var expanded : bool = to_height >= _resize_height_small
	if _resize_expanded == expanded:
		return

	_resize_expanded = expanded
	_button_grid.visible = expanded
	_button_grid_small.visible = !expanded
	$"HBoxContainer/CustomX2/HBoxContainer/Label2".visible = !expanded
	$"HBoxContainer/CustomX2/HBoxContainer3".visible = expanded
	$"HBoxContainer/HBoxContainer/NumberPanel".visible = expanded
	$"HBoxContainer/CustomX2/HBoxContainer2".visible = expanded
	$"HBoxContainer/CustomX2/HBoxContainer/Box".visible = !expanded
	$"HBoxContainer/CustomX/Label".visible = expanded


func _increment_values(by : float):
	var cell_values = sheet.get_edited_cells_values()
	if _stored_value_is_int:
		_stored_value += int(by)
		for i in cell_values.size():
			cell_values[i] += int(by)

	else:
		_stored_value += by
		for i in cell_values.size():
			cell_values[i] += by

	sheet.set_edited_cells_values(cell_values)
	_value_label.text = str(_stored_value)


func _increment_values_custom(positive : bool, multiplier : bool):
	var value := float(_custom_value_edit.text)
	if !multiplier:
		_increment_values(value if positive else -value)

	else:
		if !positive: value = 1 / value
		var cell_values = sheet.get_edited_cells_values()
		_stored_value *= value
		for i in cell_values.size():
			cell_values[i] *= value
			if _stored_value_is_int:
				cell_values[i] = int(cell_values[i])
	
		sheet.set_edited_cells_values(cell_values)
		_value_label.text = str(_stored_value)


func _on_NumberPanel_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_mouse_drag_increment = 0.0
			_mouse_down = true

		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			if _mouse_down:
				Input.warp_mouse(_value_label.global_position + _value_label.size * 0.5)
				
			_increment_values(_mouse_drag_increment)
			_mouse_down = false

	if _mouse_down and event is InputEventMouseMotion:
		if _stored_value_is_int:
			_mouse_drag_increment += event.relative.x * 0.25
			_value_label.text = str(_stored_value + int(_mouse_drag_increment))

		else:
			_mouse_drag_increment += event.relative.x * 0.01
			_value_label.text = str(_stored_value + _mouse_drag_increment)


func _on_SequenceFill_pressed(add : bool = false):
	sheet.set_edited_cells_values(_fill_sequence(sheet.get_edited_cells_values(), add))


func _fill_sequence(arr : Array, add : bool = false) -> Array:
	if !_sequence_gen_inputs.get_node("Start").text.is_valid_float():
		return arr

	var start := float(_sequence_gen_inputs.get_child(0).text)
	var end = null
	var step = null
		
	if _sequence_gen_inputs.get_node("Step").text.is_valid_float():
		step = float(_sequence_gen_inputs.get_node("Step").text)
	
	if _sequence_gen_inputs.get_node("End").text.is_valid_float():
		end = float(_sequence_gen_inputs.get_node("End").text)

	if end == null:
		end = INF if step == null or step >= 0 else -INF

	var end_is_higher =  end > start
	if step == null:
		if end == null or end == INF or end == -INF:
			step = 0.0

		else:
			step = (end - start) / arr.size()

	if _stored_value_is_int:
		if start != null:
			start = int(start)

		if step != null:
			step = int(step)

		if end != INF and end != -INF:
			end = int(end)


	var cur = start
	if !add:
		for i in arr.size():
			arr[i] = 0

	# The range() global function can also be used, but does not work with floats.
	for i in arr.size():
		arr[i] = arr[i] + cur
		cur += step
		if (end_is_higher and cur >= end) or (!end_is_higher and cur <= end):
			cur += (start - end)

	return arr
