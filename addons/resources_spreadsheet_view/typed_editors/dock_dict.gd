@tool
extends "res://addons/resources_spreadsheet_view/typed_editors/dock_array.gd"

enum {
	KEY_TYPE_STRINGNAME = 0,
	KEY_TYPE_INT,
	KEY_TYPE_FLOAT,
	KEY_TYPE_OBJECT,
	KEY_TYPE_VARIANT,
}

@onready var key_input := $"HBoxContainer/HBoxContainer/Control/VBoxContainer/KeyEdit/KeyEdit"
@onready var key_type := $"HBoxContainer/HBoxContainer/Control/VBoxContainer/KeyEdit/KeyType"

var _key_type_selected := 0


func try_edit_value(value, type, property_hint) -> bool:
	if type != TYPE_DICTIONARY and type != TYPE_OBJECT:
		return false

	if value is Texture2D:
		# For textures, prefer the specialized dock.
		return false

	key_type.visible = type != TYPE_OBJECT

	_stored_type = type
	if type == TYPE_DICTIONARY:
		_stored_value = value.duplicate()

	contents_label.text = var_to_str_no_sort(value)

	return true


func _add_value(value):
	var key = _get_key_from_box()
	_stored_value[key] = value

	var values : Array = sheet.get_edited_cells_values()
	var cur_value
	var dupe_value : bool = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "dupe_arrays")
	for i in values.size():
		cur_value = values[i]
		if dupe_value and (_stored_type == TYPE_DICTIONARY or cur_value.resource_path.rfind("::") != -1):
			cur_value = cur_value.duplicate()

		cur_value[key] = value
		values[i] = cur_value

	sheet.set_edited_cells_values(values)
	super._add_recent(key)


func _add_values(added_values : Array):
	for x in added_values:
		_add_value(x)


func _remove_value(_value):
	var key = _get_key_from_box()
	_stored_value.erase(key)

	var values : Array = sheet.get_edited_cells_values()
	var cur_value
	var dupe_value : bool = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "dupe_arrays") 
	for i in values.size():
		cur_value = values[i]
		if dupe_value and (_stored_type == TYPE_DICTIONARY or cur_value.resource_path.rfind("::") != -1):
			cur_value = cur_value.duplicate()

		cur_value.erase(key)
		values[i] = cur_value

	sheet.set_edited_cells_values(values)


func _get_key_from_box():
	if _stored_type == TYPE_OBJECT:
		return StringName(key_input.text)

	return _to_key(key_input.text, _key_type_selected)


func _to_key(from : String, key_type : int):
	match key_type:
		KEY_TYPE_STRINGNAME:
			return StringName(from)

		KEY_TYPE_INT:
			return from.to_int()

		KEY_TYPE_FLOAT:
			return from.to_float()

		KEY_TYPE_OBJECT:
			return load(from)

		KEY_TYPE_VARIANT:
			return str_to_var(from)


func _on_Replace_pressed():
	var old_key = _to_key(key_input.text, _key_type_selected)
	var new_key = _to_key(value_input.text, _key_type_selected)
	_stored_value[new_key] = _stored_value[old_key]

	var values : Array = sheet.get_edited_cells_values()
	var cur_value
	var dupe_value : bool = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "dupe_arrays") 
	for i in values.size():
		cur_value = values[i]
		if dupe_value and (_stored_type == TYPE_DICTIONARY or cur_value.resource_path.rfind("::") != -1):
			cur_value = cur_value.duplicate()

		cur_value[new_key] = cur_value[old_key]
		values[i] = cur_value

	sheet.set_edited_cells_values(values)


func _add_recent(_value):
	pass


func _on_recent_clicked(button, value):
	var val : int = recent_container.get_child(1).selected
	key_input.text = str(value)
	if val == 0:
		# Do nothing! What if the value for the key doesn't match?
		pass

	if val == 1:
		_remove_value(value)

	if val == 2:
		button.queue_free()


func _on_key_type_selected(index : int):
	_key_type_selected = index


func _on_AddRecentFromSel_pressed():
	for x in sheet.get_edited_cells_values():
		if _stored_type == TYPE_OBJECT:
			for y in x.get_property_list():
				if y[&"usage"] & PROPERTY_USAGE_EDITOR != 0:
					super._add_recent(y[&"name"])

		else:
			for y in x:
				super._add_recent(y)


func _on_contents_edit_text_changed():
	var value = str_to_var(contents_label.text)
	if !value is Dictionary:
		return

	var values : Array = sheet.get_edited_cells_values()
	for i in values.size():
		values[i] = value.duplicate()

	_stored_value = value
	sheet.set_edited_cells_values(values)


func var_to_str_no_sort(value, indent = "  ", cur_indent = ""):
	var lines : Array[String] = []

	if value is Array:
		cur_indent += indent
		lines.resize(value.size())
		for i in lines.size():
			if value[i] is Array or value[i] is Dictionary:
				lines[i] = "%s%s" % [cur_indent, var_to_str_no_sort(value[i])]

			else:
				lines[i] = "%s%s" % [cur_indent, var_to_str(value[i])]

		cur_indent = cur_indent.substr(0, cur_indent.length() - indent.length())
		return "[\n" + ",\n".join(lines) + "\n]"

	if value is Dictionary:
		var keys : Array = value.keys()
		var values : Array = value.values()
		cur_indent += indent
		lines.resize(keys.size())
		for i in lines.size():
			if values[i] is Array or values[i] is Dictionary:
				lines[i] = "%s%s : %s" % [cur_indent, var_to_str(keys[i]), var_to_str_no_sort(values[i])]

			else:
				lines[i] = "%s%s : %s" % [cur_indent, var_to_str(keys[i]), var_to_str(values[i])]

		cur_indent = cur_indent.substr(0, cur_indent.length() - indent.length())
		return "{\n" + ",\n".join(lines) + "\n}"

	return ",\n".join(lines)
