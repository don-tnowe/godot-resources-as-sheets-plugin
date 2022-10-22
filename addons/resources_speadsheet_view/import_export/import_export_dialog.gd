tool
extends WindowDialog

enum PropType {
	BOOL,
	INT,
	REAL,
	STRING,
	VECTOR2,
	RECT2,
	VECTOR3,
	COLOR,
	ARRAY,
	OBJECT,
	ENUM,
	MAX,
}

export var prop_list_item_scene : PackedScene

onready var editor_view := $"../.."
onready var node_filename_options := $"TabContainer/Import/MarginContainer/ScrollContainer/VBoxContainer/GridContainer/OptionButton"
onready var node_classname_field := $"TabContainer/Import/MarginContainer/ScrollContainer/VBoxContainer/GridContainer/LineEdit"
onready var node_filename_props := $"TabContainer/Import/MarginContainer/ScrollContainer/VBoxContainer/GridContainer/OptionButton"
onready var prop_list := $"TabContainer/Import/MarginContainer/ScrollContainer/VBoxContainer"

var prop_types := []
var prop_names := []

var entries := []
var uniques := {}
var delimeter := ""

var path := "res://"
var property_used_as_filename := 0
var script_classname := ""
var remove_first_row := true

var new_script : GDScript


func _on_FileDialogText_file_selected(path : String):
	self.path = path
	_open_dialog()
	popup_centered()


func _open_dialog():
	node_classname_field.text = TextEditingUtils\
		.string_snake_to_naming_case(path.get_file().get_basename())\
		.replace(" ", "")
	
	_load_entries()
	_load_property_names()
	_create_prop_editors()


func _load_entries():
	var file = File.new()
	file.open(path, File.READ)

	delimeter = ";"
	var text_lines := [file.get_line().split(delimeter)]
	var line = text_lines[0]
	if line.size() == 1:
		delimeter = ","
		text_lines[0] = text_lines[0][0].split(delimeter)

	while !file.eof_reached():
		line = file.get_csv_line(delimeter)
		if line.size() == text_lines[0].size():
			text_lines.append(line)

	entries = []
	entries.resize(text_lines.size())

	for i in entries.size():
		entries[i] = text_lines[i]


func _load_property_names():
	prop_names = Array(entries[0])
	prop_types.resize(prop_names.size())
	prop_types.fill(4)
	for i in prop_names.size():
		prop_names[i] = entries[0][i].replace(" ", "_").to_lower()
		if entries[1][i].is_valid_integer():
			prop_types[i] = PropType.INT

		elif entries[1][i].is_valid_float():
			prop_types[i] = PropType.REAL
				
		elif entries[1][i].begins_with("res://"):
			prop_types[i] = PropType.OBJECT

		else: prop_types[i] = PropType.STRING
	
	node_filename_options.clear()
	for i in prop_names.size():
		node_filename_options.add_item(prop_names[i], i)


func _create_prop_editors():
	for x in prop_list.get_children():
		if !x is GridContainer: x.free()

	for i in prop_names.size():
		var new_node = prop_list_item_scene.instance()
		prop_list.add_child(new_node)
		new_node.display(prop_names[i], prop_types[i])
		new_node.connect_all_signals(self, i)


func _generate_class():
	new_script = GDScript.new()
	if script_classname != "":
		new_script.source_code = "class_name " + script_classname + " \nextends Resource\n\n"

	else:
		new_script.source_code = "extends Resource\n\n"
	
	# Enums
	uniques = {}
	for i in prop_types.size():
		if prop_types[i] == PropType.ENUM:
			new_script.source_code += _create_enum_for_prop(i)

	# Properties
	for i in prop_names.size():
		new_script.source_code += _create_property_line_for_prop(i)

	ResourceSaver.save(path.get_basename() + ".gd", new_script)
	new_script.reload()
	new_script = load(path.get_basename() + ".gd")  # Because when instanced, objects have a copy of the script


func _export_tres_folder():
	var dir = Directory.new()
	dir.make_dir_recursive(path.get_basename())

	var prop_used_as_filename_str : String = prop_names[property_used_as_filename]
	var new_res : Resource
	for i in entries.size():
		if remove_first_row && i == 0:
			continue

		new_res = new_script.new()
		for j in prop_names.size():
			new_res.set(prop_names[j], _string_to_property(entries[i][j], j))
		
		new_res.resource_path = path.get_basename() + "/" + new_res.get(prop_used_as_filename_str) + ".tres"
		ResourceSaver.save(new_res.resource_path, new_res)


func _create_property_line_for_prop(col_index : int):
	var result = "export var " + prop_names[col_index] + " :"
	match prop_types[col_index]:
		PropType.STRING:
			return result + "= \"\"\n"

		PropType.BOOL:
			return result + "= false\n"

		PropType.REAL:
			return result + "= 0.0\n"

		PropType.INT:
			return result + "= 0\n"

		PropType.COLOR:
			return result + "= Color.white\n"

		PropType.OBJECT:
			return result + " Resource\n"

		PropType.ENUM:
			return result.replace(
				"export var",
				"export("
					+ TextEditingUtils.string_snake_to_naming_case(
						prop_names[col_index]
					).replace(" ", "")
					+ ") var"
			) + "= 0\n"


func _create_enum_for_prop(col_index):
	# Find all uniques
	var cur_value := ""
	uniques[col_index] = {}
	for i in entries.size():
		if i == 0 && remove_first_row: continue

		cur_value = entries[i][col_index].replace(" ", "_").to_upper()
		if cur_value == "":
			cur_value = "N_A"
		
		if !uniques[col_index].has(cur_value):
			uniques[col_index][cur_value] = uniques[col_index].size()
	
	# Write to script
	var result := (
		"enum "
		+ TextEditingUtils.string_snake_to_naming_case(prop_names[col_index]).replace(" ", "")
		+ " {\n"
	)
	for k in uniques[col_index]:
		result += (
			"\t"
			+ k  # Enum Entry
			+ " = "
			+ str(uniques[col_index][k])  # Value
			+ ",\n"
		)
	result += "\tMAX,\n}\n\n"
	return result


func _string_to_property(string : String, col_index : int):
	match prop_types[col_index]:
		PropType.STRING:
			return string

		PropType.BOOL:
			string = string.to_lower()
			return !string in ["no", "disabled", "-", "false", "absent", "wrong", ""]

		PropType.REAL:
			return string.to_float()

		PropType.INT:
			return string.to_int()

		PropType.COLOR:
			return Color(string)

		PropType.OBJECT:
			return load(string)

		PropType.ENUM:
			if string == "":
				return int(uniques[col_index]["N_A"])

			else:
				return int(uniques[col_index][string.to_upper().replace(" ", "_")])


func _on_Ok_pressed():
	hide()
	_generate_class()
	_export_tres_folder()
	yield(get_tree(), "idle_frame")
	editor_view.display_folder(path.get_basename())
	yield(get_tree(), "idle_frame")
	editor_view.refresh()

# Input controls
func _on_classname_field_text_changed(new_text : String):
	script_classname = new_text.replace(" ", "")


func _on_remove_first_row_toggled(button_pressed : bool):
	remove_first_row = button_pressed


func _on_filename_options_item_selected(index):
	property_used_as_filename = index


func _on_list_item_type_selected(type : int, index : int):
	prop_types[index] = type
	

func _on_list_item_name_changed(name : String, index : int):
	prop_names[index] = name.replace(" ", "")
