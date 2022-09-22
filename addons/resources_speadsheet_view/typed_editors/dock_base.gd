tool
class_name SheetsDockEditor
extends Control

export var path_property_name := NodePath("Header/Label")

var sheet : Control
var selection : Array


func _ready():
	var parent := get_parent()
	while parent != null and !parent.has_method("select_cell"):
		parent = parent.get_parent()

	sheet = parent
	get_node(path_property_name).add_font_override("bold", get_font("bold", "EditorFonts"))

# Override to define when to show the dock and, if it can edit the value, how to handle it.
func try_edit_value(value, type, property_hint) -> bool:
	return true
