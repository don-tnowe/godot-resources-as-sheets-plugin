tool
class_name ThemeStylebox
extends Control

export var box_class := "EditorStyles" setget _set_box_class
export var box_name := "Background" setget _set_box_name


func _ready():
	_set_box_name(box_name)
	_set_box_class(box_class)


func _set_box_name(v):
	box_name = v
	add_stylebox_override(box_name, get_stylebox(box_name, box_class))


func _set_box_class(v):
	box_class = v
	add_stylebox_override(box_name, get_stylebox(box_name, box_class))
