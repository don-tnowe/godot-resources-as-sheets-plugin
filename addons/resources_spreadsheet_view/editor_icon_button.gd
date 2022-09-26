@tool
class_name ThemeIconButton
extends Button

@export var icon_name := "Node" :
	set(v):
		icon_name = v
		icon = get_theme_icon(v, "EditorIcons")


func _ready():
	self.icon_name = (icon_name)
