tool
class_name ThemeIconButton
extends Button

export var icon_name := "Node" setget _set_icon_name


func _ready():
	_set_icon_name(icon_name)


func _set_icon_name(v):
	icon_name = v
	icon = get_icon(v, "EditorIcons")
