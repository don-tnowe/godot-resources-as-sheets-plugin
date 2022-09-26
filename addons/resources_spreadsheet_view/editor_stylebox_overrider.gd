@tool
class_name ThemeStylebox
extends Control

@export var box_class := "EditorStyles"
@export var box_name := "Background"


func _ready():
	_set_box_name(box_name)
	_set_box_class(box_class)


func _set_box_name(v):
	box_name = v
	add_theme_stylebox_override(box_name, get_theme_stylebox(box_name, box_class))


func _set_box_class(v):
	box_class = v
	add_theme_stylebox_override(box_name, get_theme_stylebox(box_name, box_class))
