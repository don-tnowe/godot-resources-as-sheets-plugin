@tool
extends GridContainer

signal format_changed(case : int, delimiter : String, bool_yes : String, bool_no: String)


func set_format_array(format : Array):
	_on_format_changed(format[0], format[1], format[2], format[3])
	format_changed.emit(format[0], format[1], format[2], format[3])


func set_format(case : int, delimiter : String, bool_yes : String, bool_no: String):
	_on_format_changed(case, delimiter, bool_yes, bool_no)
	format_changed.emit(case, delimiter, bool_yes, bool_no)


func _send_signal(arg1 = null):
	format_changed.emit(
		$"HBoxContainer/Case".selected,
		[" ", "_", "-"][$"HBoxContainer/Separator".selected],
		$"HBoxContainer2/True".text,
		$"HBoxContainer2/False".text
	)


func _on_format_changed(case : int, delimiter : String, bool_yes : String, bool_no: String):
	$"HBoxContainer/Case".selected = case
	$"HBoxContainer/Separator".selected = [" ", "_", "-"].find(delimiter)
	$"HBoxContainer2/True".text = bool_yes
	$"HBoxContainer2/False".text = bool_no
