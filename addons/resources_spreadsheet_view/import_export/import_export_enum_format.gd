tool
extends GridContainer

signal format_changed(case, delimiter, bool_yes, bool_no)


func _send_signal(arg1 = null):
	emit_signal(
		"format_changed",
		$"HBoxContainer/Case".selected,
		[" ", "_", "-"][$"HBoxContainer/Separator".selected],
		$"HBoxContainer2/True".text,
		$"HBoxContainer2/False".text
	)


func _on_format_changed(case, delimiter, bool_yes, bool_no):
	$"HBoxContainer/Case".selected = case
	$"HBoxContainer/Separator".selected = [" ", "_", "-"].find(delimiter)
	$"HBoxContainer2/True".text = bool_yes
	$"HBoxContainer2/False".text = bool_no
