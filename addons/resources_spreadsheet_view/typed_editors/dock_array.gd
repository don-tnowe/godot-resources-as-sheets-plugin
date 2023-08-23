@tool
extends ResourceTablesDockEditor

@onready var recent_container := $"HBoxContainer/Control2/HBoxContainer/HFlowContainer"
@onready var contents_label := $"HBoxContainer/HBoxContainer/Panel/Label"
@onready var button_box := $"HBoxContainer/HBoxContainer/Control/VBoxContainer/HBoxContainer"
@onready var value_input := $"HBoxContainer/HBoxContainer/Control/VBoxContainer/LineEdit"

var _stored_value
var _stored_type := 0


func _ready():
	super()
	contents_label.text_changed.connect(_on_contents_edit_text_changed)


func try_edit_value(value, type, property_hint) -> bool:
	if (
		type != TYPE_ARRAY and type != TYPE_PACKED_STRING_ARRAY
		and type != TYPE_PACKED_INT32_ARRAY and type != TYPE_PACKED_FLOAT32_ARRAY
		and type != TYPE_PACKED_INT64_ARRAY and type != TYPE_PACKED_FLOAT64_ARRAY
	):
		return false

	if sheet.column_hint_strings[sheet.get_selected_column()][0].begins_with("2/2:"):
		# For enums, prefer the specialized dock.
		return false

	_stored_type = type
	_stored_value = value.duplicate()  # Generic arrays are passed by reference
	contents_label.text = str(value)
	
	var is_generic_array = _stored_type == TYPE_ARRAY and !value.is_typed()
	button_box.get_child(1).visible = (
		is_generic_array or value.get_typed_builtin() == TYPE_STRING
		or _stored_type == TYPE_PACKED_STRING_ARRAY
	)
	button_box.get_child(2).visible = (
		is_generic_array or value.get_typed_builtin() == TYPE_INT
		or _stored_type == TYPE_PACKED_INT32_ARRAY or _stored_type == TYPE_PACKED_INT64_ARRAY
	)
	button_box.get_child(3).visible = (
		is_generic_array or value.get_typed_builtin() == TYPE_FLOAT
		or _stored_type == TYPE_PACKED_FLOAT32_ARRAY or _stored_type == TYPE_PACKED_FLOAT64_ARRAY
	)
	button_box.get_child(5).visible = (
		is_generic_array or value.get_typed_builtin() == TYPE_OBJECT
	)

	if value.get_typed_builtin() == TYPE_OBJECT:
		if !value_input is EditorResourcePicker:
			var new_input := EditorResourcePicker.new()
			new_input.size_flags_horizontal = SIZE_EXPAND_FILL
			new_input.base_type = value.get_typed_class_name()

			value_input.replace_by(new_input)
			value_input.free()
			value_input = new_input

	else:
		if !value_input is LineEdit:
			var new_input := LineEdit.new()
			new_input.size_flags_horizontal = SIZE_EXPAND_FILL

			value_input.replace_by(new_input)
			value_input.free()
			value_input = new_input

	return true


func _add_value(value):
	_stored_value.append(value)
	var values = sheet.get_edited_cells_values()
	var cur_value
	var dupe_array : bool = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "dupe_arrays") 
	for i in values.size():
		cur_value = values[i]
		if dupe_array:
			cur_value = cur_value.duplicate()

		cur_value.append(value)
		values[i] = cur_value

	sheet.set_edited_cells_values(values)


func _remove_value(value):
	_stored_value.remove_at(_stored_value.find(value))
	var values = sheet.get_edited_cells_values()
	var cur_value : Array
	var dupe_array : bool = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "dupe_arrays") 
	for i in values.size():
		cur_value = values[i]
		if dupe_array:
			cur_value = cur_value.duplicate()

		if cur_value.has(value): # erase() not defined in PoolArrays
			cur_value.remove_at(cur_value.find(value))
		
		values[i] = cur_value

	sheet.set_edited_cells_values(values)


func _add_recent(value):
	for x in recent_container.get_children():
		if x.text == str(value):
			return

		if value is Resource and x.tooltip_text == value.resource_path:
			return

	var node := Button.new()
	var value_str : String = str(value)
	if value is Resource:
		value_str = value.resource_path.get_file()
		node.tooltip_text = value.resource_path
		value = value.resource_path

	node.text = value_str
	node.self_modulate = Color(value_str.hash()) + Color(0.25, 0.25, 0.25, 1.0)
	node.pressed.connect(_on_recent_clicked.bind(node, value))
	recent_container.add_child(node)


func _on_recent_clicked(button, value):
	var val = recent_container.get_child(1).selected
	value_input.text = str(value)
	if val == 0:
		_add_value(value)

	if val == 1:
		_remove_value(value)

	if val == 2:
		button.queue_free()


func _on_Remove_pressed():
	if value_input is EditorResourcePicker:
		_remove_value(value_input.edited_resource)

	elif str_to_var(value_input.text) != null:
		_remove_value(str_to_var(value_input.text))
		
	else:
		_remove_value(value_input.text)


func _on_RemoveLast_pressed():
	_stored_value.pop_back()
	var values = sheet.get_edited_cells_values()
	var cur_value : Array
	var dupe_array : bool = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "dupe_arrays") 
	for i in values.size():
		cur_value = values[i]
		if dupe_array:
			cur_value = cur_value.duplicate()

		cur_value.pop_back()
		values[i] = cur_value

	sheet.set_edited_cells_values(values)


func _on_ClearRecent_pressed():
	for i in recent_container.get_child_count():
		if i == 0: continue
		recent_container.get_child(i).free()
	

func _on_Float_pressed():
	_add_value(value_input.text.to_float())


func _on_Int_pressed():
	_add_value(value_input.text.to_int())


func _on_String_pressed():
	_add_value(value_input.text)
	_add_recent(value_input.text)


func _on_Variant_pressed():
	if value_input is EditorResourcePicker:
		_add_value(value_input.edited_resource)
	
	else:
		_add_value(str_to_var(value_input.text))


func _on_Resource_pressed():
	if value_input is LineEdit:
		_add_value(load(value_input.text))

	elif value_input is EditorResourcePicker:
		_add_value(value_input.edited_resource)


func _on_AddRecentFromSel_pressed():
	for x in sheet.get_edited_cells_values():
		for y in x:
			_add_recent(y)


func _on_contents_edit_text_changed():
	var value := str_to_var(contents_label.text)
	if !value is Array:
		return

	var values = sheet.get_edited_cells_values()
	for i in values.size():
		values[i] = values[i].duplicate()
		values[i].resize(value.size())
		for j in value.size():
			values[i][j] = value[j]

	_stored_value = value
	sheet.set_edited_cells_values(values)
