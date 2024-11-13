@tool
extends ResourceTablesDockEditor

@onready var options_container := $"HBoxContainer/Control2/HBoxContainer/HFlowContainer"
@onready var contents_label := $"HBoxContainer/HBoxContainer/Panel/Label"

@onready var _init_nodes_in_options_container := options_container.get_child_count()

var _stored_value
var _last_column := -1


func _ready():
	super()
	contents_label.text_changed.connect(_on_contents_edit_text_changed)


func try_edit_value(value, type, property_hint) -> bool:
	if !sheet.column_hint_strings[sheet.get_selected_column()][0].begins_with("2/2:"):
		return false

	_stored_value = value.duplicate()  # Generic arrays are passed by reference
	if _last_column != sheet.get_selected_column():
		_last_column = sheet.get_selected_column()
		for x in options_container.get_children():
			x.visible = x.get_index() < _init_nodes_in_options_container

		for i in sheet.column_hint_strings[sheet.get_selected_column()].size():
			_create_option_button(i)

	contents_label.text = str(value)
	return true


func _create_option_button(index : int):
	var value = sheet.column_hint_strings[sheet.get_selected_column()][index]
	if index == 0:
		# Enum array hints have "2/3:" before list.
		value = value.substr(value.find(":") + 1)

	var node
	if index >= options_container.get_child_count() - _init_nodes_in_options_container:
		node = Button.new()
		options_container.add_child(node)
		var colon_found : int = value.rfind(":")
		if colon_found == -1:
			node.pressed.connect(_on_option_clicked.bind(index))

		else:
			node.pressed.connect(_on_option_clicked.bind(value.substr(colon_found + 1).to_int()))

	else:
		node = options_container.get_child(index + _init_nodes_in_options_container)
		node.visible = true

	node.text = str(value)
	node.self_modulate = Color(value.hash()) + Color(0.25, 0.25, 0.25, 1.0)
	return node


func _add_value(option_value : int):
	_stored_value.append(option_value)
	var values = sheet.get_edited_cells_values()
	var cur_value
	var dupe_array : bool = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "dupe_arrays") 
	for i in values.size():
		cur_value = values[i]
		if dupe_array:
			cur_value = cur_value.duplicate()

		cur_value.append(option_value)
		values[i] = cur_value

	sheet.set_edited_cells_values(values)


func _remove_value(option_value : int):
	_stored_value.append(option_value)
	var values = sheet.get_edited_cells_values()
	var cur_value
	var dupe_array : bool = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "dupe_arrays") 
	for i in values.size():
		cur_value = values[i]
		if dupe_array:
			cur_value = cur_value.duplicate()

		if cur_value.has(option_value):
			cur_value.remove_at(cur_value.find(option_value))
			
		values[i] = cur_value

	sheet.set_edited_cells_values(values)


func _on_option_clicked(value : int):
	var val = options_container.get_child(1).selected
	if val == 0:
		_add_value(value)

	if val == 1:
		_remove_value(value)


func _on_Remove_pressed():
	_stored_value.remove_at(_stored_value.size() - 1)
	var values = sheet.get_edited_cells_values()
	var cur_value
	var dupe_array : bool = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "dupe_arrays") 
	for i in values.size():
		cur_value = values[i]
		if dupe_array:
			cur_value = cur_value.duplicate()

		cur_value.remove_at(cur_value.size() - 1)
		values[i] = cur_value

	sheet.set_edited_cells_values(values)


func _on_contents_edit_text_changed():
	var value := str_to_var(contents_label.text)
	if !value is Array:
		return

	for x in value:
		if !x is int:
			return

	var values = sheet.get_edited_cells_values()
	for i in values.size():
		values[i] = values[i].duplicate()
		values[i].resize(value.size())
		for j in value.size():
			values[i][j] = value[j]

	_stored_value = value
	sheet.set_edited_cells_values(values)
