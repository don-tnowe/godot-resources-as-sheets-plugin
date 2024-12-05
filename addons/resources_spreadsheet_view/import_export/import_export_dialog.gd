@tool
extends Control

@export var prop_list_item_scene : PackedScene
@export var formats_export : Array[Script]
@export var formats_import : Array[Script]

@onready var editor_view := $"../../.."
@onready var filename_options := $"Import/Margins/Scroll/Box/Grid/UseAsFilename"
@onready var classname_field := $"Import/Margins/Scroll/Box/Grid/Classname"
@onready var script_path_field := $"Import/Margins/Scroll/Box/Grid/HBoxContainer/LineEdit"
@onready var prop_list := $"Import/Margins/Scroll/Box"
@onready var format_settings := $"Import/Margins/Scroll/Box/StyleSettingsI"
@onready var file_dialog := $"../../FileDialogText"

var format_extension := ".csv"
var entries := []

var import_data : ResourceTablesImport


func _ready():
	hide()
	show()
	get_parent().min_size = Vector2(600, 400)
	get_parent().size = Vector2(600, 400)


func _on_file_selected(path : String):
	if !FileAccess.file_exists(path):
		if path.get_extension() != "":
			# Path is a file path: replace extension
			path = path.get_basename() + ".csv"

		else:
			# Path is a directory: add filename, add extension
			path = path.path_join(editor_view.current_path.trim_suffix("/").get_file()) + ".csv"

		FileAccess.open(path, FileAccess.WRITE)

	import_data = null
	for x in DirAccess.get_files_at(path.get_base_dir()):
		if !x.ends_with(".tres"):
			continue

		var found_res := load(path.get_base_dir().path_join(x))
		if !(found_res is ResourceTablesImport):
			continue

		import_data = found_res
		_load_settings_from_import_file(found_res)
		for format_x in formats_import:
			if format_x.new().can_edit_path(path):
				entries = format_x.new().import_as_arrays(import_data)

		break

	if import_data == null:
		import_data = ResourceTablesImport.new()
		import_data.initialize(path)

		for format_x in formats_import:
			if format_x.new().can_edit_path(path):
				entries = format_x.new().import_as_arrays(import_data)

		classname_field.text = import_data.edited_path.get_file().get_basename()\
			.capitalize().replace(" ", "")
		import_data.script_classname = classname_field.text

		_load_property_names_from_textfile(path)

	_create_prop_editors()
	$"Import/Margins/Scroll/Box/StyleSettingsI"._send_signal()

	await get_tree().process_frame
	get_parent().popup_centered()
	position = Vector2.ZERO


func _on_files_selected(paths : PackedStringArray):
	_on_file_selected(paths[0])


func _load_property_names_from_textfile(path : String):
	var prop_types := import_data.prop_types
	prop_types.resize(import_data.prop_names.size())
	prop_types.fill(4)
	for i in import_data.prop_names.size():
		import_data.prop_names[i] = entries[0][i]\
			.replace("\"", "")\
			.replace(" ", "_")\
			.replace("-", "_")\
			.replace(".", "_")\
			.replace(",", "_")\
			.replace("\t", "_")\
			.replace("/", "_")\
			.replace("\\", "_")\
			.to_lower()

		# Don't guess Ints automatically - further rows might have floats
		if entries[1][i].is_valid_float():
			prop_types[i] = ResourceTablesImport.PropType.FLOAT

		elif entries[1][i].begins_with("res://"):
			prop_types[i] = ResourceTablesImport.PropType.OBJECT

		else:
			prop_types[i] = ResourceTablesImport.PropType.STRING

	filename_options.clear()
	for i in import_data.prop_names.size():
		filename_options.add_item(import_data.prop_names[i], i)


func _load_settings_from_import_file(from_file : ResourceTablesImport):
	filename_options.clear()
	for i in import_data.prop_names.size():
		filename_options.add_item(import_data.prop_names[i], i)

	if import_data.new_script != null:
		classname_field.text = import_data.new_script.get_global_name()
		script_path_field.text = from_file.new_script.resource_path

	format_settings.set_format_array(import_data.enum_format)


func _create_prop_editors():
	for x in prop_list.get_children():
		if !x is GridContainer: x.free()

	for i in import_data.prop_names.size():
		var new_node := prop_list_item_scene.instantiate()
		prop_list.add_child(new_node)
		new_node.display(import_data.prop_names[i], import_data.prop_types[i])
		new_node.connect_all_signals(self, i)


func _generate_class(save_script = true):
	save_script = true  # Built-ins didn't work in 3.x, won't change because dont wanna test rn
	import_data.new_script = import_data.generate_script(entries, save_script)
	if save_script:
		import_data.new_script.resource_path = import_data.edited_path.get_basename() + ".gd"
		ResourceSaver.save(import_data.new_script)
		# Because when instanced, objects have a copy of the script
		import_data.new_script = load(import_data.edited_path.get_basename() + ".gd")


func _on_import_to_tres_pressed():
	if script_path_field.text != "":
		import_data.load_external_script(load(script_path_field.text))

	if import_data.new_script == null:
		_generate_class()

	DirAccess.open("res://").make_dir_recursive(import_data.edited_path.get_basename())

	import_data.prop_used_as_filename = import_data.prop_names[filename_options.selected]
	var new_res : Resource
	for i in entries.size():
		if import_data.remove_first_row and i == 0:
			continue

		new_res = import_data.strings_to_resource(entries[i], editor_view.current_path)
		ResourceSaver.save(new_res)

	await get_tree().process_frame
	await get_tree().process_frame
	editor_view.refresh()
	close()


func _on_import_edit_pressed():
	if import_data.new_script == null:
		_generate_class(false)

	import_data.prop_used_as_filename = ""
	import_data.save()
	await get_tree().process_frame
	editor_view.display_folder(import_data.resource_path)
	editor_view.node_columns.hidden_columns[editor_view.current_path] = {
		"resource_path" : true,
		"resource_local_to_scene" : true,
	}
	editor_view.save_data()
	await get_tree().process_frame
	editor_view.refresh()
	close()


func _on_export_csv_pressed():
	var exported_cols : Array = editor_view.columns.duplicate()
	exported_cols.erase(&"resource_local_to_scene")
	for x in editor_view.node_columns.hidden_columns[editor_view.current_path].keys():
		exported_cols.erase(x)

	ResourceTablesExportFormatCsv.export_to_file(editor_view.rows, exported_cols, import_data.edited_path, import_data)
	await get_tree().process_frame
	editor_view.refresh()
	close()

# Input controls
func _on_classname_field_text_changed(new_text : String):
	import_data.script_classname = new_text.replace(" ", "")


func _on_remove_first_row_toggled(button_pressed : bool):
	import_data.remove_first_row = button_pressed
#	$"Export/Box2/Button".button_pressed = true
	$"Export/Box3/CheckBox".button_pressed = button_pressed


func _on_list_item_type_selected(type : int, index : int):
	import_data.prop_types[index] = type
	

func _on_list_item_name_changed(name : String, index : int):
	import_data.prop_names[index] = name.replace(" ", "")


func _on_export_delimeter_pressed(del : String):
	import_data.delimeter = del + import_data.delimeter.substr(1)


func _on_export_space_toggled(button_pressed : bool):
	import_data.delimeter = (
		import_data.delimeter[0]
		if !button_pressed else
		import_data.delimeter + " "
	)


func _on_enum_format_changed(case, delimiter, bool_yes, bool_no):
	import_data.enum_format = [case, delimiter, bool_yes, bool_no]


func close():
	get_parent().hide()
