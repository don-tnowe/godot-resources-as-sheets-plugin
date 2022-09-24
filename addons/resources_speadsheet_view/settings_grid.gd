tool
class_name SettingsGrid
extends GridContainer

const SETTING_PREFIX = "addons/resources_spreadsheet_view/"


func _ready():
  for x in get_children():
    var setting = SETTING_PREFIX + camel_case_to_snake_case(x.name)
    if x is BaseButton:
      x.connect("toggled", self, "_set_setting", [setting])
      if !ProjectSettings.has_setting(setting):
        call("_set_setting", x.pressed, setting)

      else:
        x.pressed = ProjectSettings.get_setting(setting)

    elif x is Range:
      x.connect("value_changed", self, "_set_setting", [setting])
      if !ProjectSettings.has_setting(setting):
        call("_set_setting", x.value, setting)

      else:
        x.value = ProjectSettings.get_setting(setting)


static func camel_case_to_snake_case(string : String) -> String:
  var i = 0
  while i < string.length():
    if string.ord_at(i) < 97:
      string = string.left(i) + ("_" if i > 0 else "") + string[i].to_lower() + string.substr(i + 1)
      i += 1
    
    i += 1

  return string


func _set_setting(new_value, setting):
  ProjectSettings.set_setting(setting, new_value)
