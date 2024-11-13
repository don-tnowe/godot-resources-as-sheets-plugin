@tool
extends GridContainer

const PREFIX = "addons/resources_spreadsheet_view/"


func _ready():
	ProjectSettings.set_setting(PREFIX + "array_color_tint", 100.0 if ProjectSettings.get_setting(PREFIX + "color_arrays", true) else 0.0)
	ProjectSettings.set_setting(PREFIX + "color_arrays", null)

	for x in get_children():
		var setting : String = PREFIX + x.name.to_snake_case()
		if x is BaseButton:
			x.toggled.connect(_set_setting.bind(setting))
			if !ProjectSettings.has_setting(setting):
				_set_setting(x.button_pressed, setting)

			else:
				x.button_pressed = ProjectSettings.get_setting(setting)

		elif x is Range:
			x.value_changed.connect(_set_setting.bind(setting))
			if !ProjectSettings.has_setting(setting):
				_set_setting(x.value, setting)

			else:
				x.value = ProjectSettings.get_setting(setting)


func _set_setting(new_value, setting : String):
	ProjectSettings.set_setting(setting, new_value)
