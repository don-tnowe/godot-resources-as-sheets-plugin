@tool
class_name SettingsGrid
extends GridContainer

const SETTING_PREFIX = "addons/resources_spreadsheet_view/"


func _ready():
	for x in get_children():
		var setting = SETTING_PREFIX + camel_case_to_snake_case(x.name)
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


static func camel_case_to_snake_case(string : String) -> String:
	var i = 0
	while i < string.length():
		if string.unicode_at(i) < 97:
			string = string.left(i) + ("_" if i > 0 else "") + string[i].to_lower() + string.substr(i + 1)
			i += 1
		
		i += 1

	return string


func _set_setting(new_value, setting):
	ProjectSettings.set_setting(setting, new_value)
