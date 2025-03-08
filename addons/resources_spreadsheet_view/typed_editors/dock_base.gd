@tool
class_name ResourceTablesDockEditor
extends Control

const TablesPluginSettingsClass := preload("res://addons/resources_spreadsheet_view/settings_grid.gd")

@export var path_property_name := NodePath("Header/Label")

var sheet : Control
var selection : Array

var _resize_target_height := 0.0
var _resize_pressed := false


func _ready():
	var parent := get_parent()
	while parent != null and !parent.has_method(&"display_folder"):
		parent = parent.get_parent()

	sheet = parent
	get_node(path_property_name).add_theme_font_override(&"normal", get_theme_font(&"bold", &"EditorFonts"))

	$"Header".gui_input.connect(_on_header_gui_input)
	$"Header".mouse_filter = MOUSE_FILTER_STOP
	$"Header".mouse_default_cursor_shape = CURSOR_VSIZE

## Override to define when to show the dock and, if it can edit the value, how to handle it.
func try_edit_value(value, type : int, property_hint : String) -> bool:
	return true

## Override to define behaviour when stretching the header to change size.
func resize_drag(to_height : float):
	return


func resize_set_hidden(state : bool):
	get_child(1).visible = !state


func _on_header_gui_input(event : InputEvent):
	if event is InputEventMouseMotion and _resize_pressed:
		_resize_target_height -= event.relative.y
		custom_minimum_size.y = clamp(_resize_target_height, 0.0, get_viewport().size.y * 0.75)
		resize_drag(_resize_target_height)
		resize_set_hidden(_resize_target_height <= $"Header".size.y)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_resize_pressed = event.pressed
		_resize_target_height = custom_minimum_size.y
