@tool
class_name ThemeColorSetter
extends Control


func _ready():
	modulate = get_theme_color("accent_color", "Editor")
