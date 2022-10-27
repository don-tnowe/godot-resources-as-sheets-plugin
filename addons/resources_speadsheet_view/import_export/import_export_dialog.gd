tool
extends WindowDialog

export var prop_list_item_scene : PackedScene
export(Array, Script) var formats_export
export(Array, Script) var formats_import

onready var editor_view := $"../.."
onready var node_filename_options := $"TabContainer/Import/MarginContainer/ScrollContainer/VBoxContainer/GridContainer/OptionButton"
onready var node_classname_field := $"TabContainer/Import/MarginContainer/ScrollContainer/VBoxContainer/GridContainer/LineEdit"
onready var node_filename_props := $"TabContainer/Import/MarginContainer/ScrollContainer/VBoxContainer/GridContainer/OptionButton"
onready var prop_list := $"TabContainer/Import/MarginContainer/ScrollContainer/VBoxContainer"

var entries := []

var property_used_as_filename := 0
var import_data : SpreadsheetImport


func _ready():
	var create_file_button = Button.new()
	create_file_button.connect("pressed", self, "_on_create_file_pressed")
	$"../FileDialogText".get_child(3).get_child(3).add_child_below_node(
		$"../FileDialogText".get_child(3).get_child(3).get_child(1),
		create_file_button
	)
	create_file_button.text = "Create File"
	create_file_button.visible = true
	create_file_button.icon = get_icon("New", "EditorIcons")


func _on_create_file_pressed():
	var file = File.new()
	var new_name = (
		$"../FileDialogText".get_child(3).get_child(3).get_child(1).text
	)
	if new_name == "":
		new_name += editor_view.current_path.get_base_dir().get_file()

	file.open(
		$"../FileDialogText".get_child(3).get_child(0).get_child(4).text
		+ "/"
		+ new_name.get_basename() + ".csv", File.WRITE
	)
	file.close()
	$"../FileDialogText".invalidate()


func _on_FileDialogText_file_selected(path : String):
	import_data = SpreadsheetImport.new()
	import_data.initialize(path)
	_reset_controls()
	_open_dialog(path)
	popup_centered()


func _open_dialog(path : String):
	node_classname_field.text = import_data.edited_path.get_file().get_basename()\
		.capitalize().replace(" ", "")
	import_data.script_classname = node_classname_field.text

	for x in formats_import:
		if x.new().can_edit_path(path):
			entries = x.new().import_as_arrays(import_data)

	_load_property_names()
	_create_prop_editors()
	$"TabContainer/Import/MarginContainer/ScrollContainer/VBoxContainer/StyleSettingsI"._send_signal()


func _load_property_names():
	import_data.prop_names = Array(entries[0])
	import_data.prop_types.resize(import_data.prop_names.size())
	import_data.prop_types.fill(4)
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
		
		# Don't imply Ints automatically - further rows might have floats
		if entries[1][i].is_valid_float():
			import_data.prop_types[i] = SpreadsheetImport.PropType.REAL
				
		elif entries[1][i].begins_with("res://"):
			import_data.prop_types[i] = SpreadsheetImport.PropType.OBJECT

		else: import_data.prop_types[i] = SpreadsheetImport.PropType.STRING
	
	node_filename_options.clear()
	for i in import_data.prop_names.size():
		node_filename_options.add_item(import_data.prop_names[i], i)


func _create_prop_editors():
	for x in prop_list.get_children():
		if !x is GridContainer: x.free()

	for i in import_data.prop_names.size():
		var new_node = prop_list_item_scene.instance()
		prop_list.add_child(new_node)
		new_node.display(import_data.prop_names[i], import_data.prop_types[i])
		new_node.connect_all_signals(self, i)


func _generate_class(save_script = true):
	save_script = true  # Built-ins work no more. Why? No idea. But they worked for a bit.
	import_data.new_script = import_data.generate_script(entries, save_script)
	if save_script:
		ResourceSaver.save(import_data.edited_path.get_basename() + ".gd", import_data.new_script)
		# Because when instanced, objects have a copy of the script
		import_data.new_script = load(import_data.edited_path.get_basename() + ".gd")


func _export_tres_folder():
	var dir = Directory.new()
	dir.make_dir_recursive(import_data.edited_path.get_basename())

	import_data.prop_used_as_filename = import_data.prop_names[property_used_as_filename]
	var new_res : Resource
	for i in entries.size():
		if import_data.remove_first_row && i == 0:
			continue
	
		new_res = import_data.strings_to_resource(entries[i])
		ResourceSaver.save(new_res.resource_path, new_res)


func _on_import_to_tres_pressed():
	hide()
	_generate_class()
	_export_tres_folder()
	yield(get_tree(), "idle_frame")
	editor_view.display_folder(import_data.edited_path.get_basename() + "/")
	yield(get_tree(), "idle_frame")
	editor_view.refresh()


func _on_import_edit_pressed():
	hide()
	_generate_class(false)
	import_data.prop_used_as_filename = ""
	import_data.save()
	yield(get_tree(), "idle_frame")
	editor_view.display_folder(import_data.resource_path)
	editor_view.hidden_columns[editor_view.current_path] = {
		"resource_path" : true,
		"resource_local_to_scene" : true,
	}
	editor_view.save_data()
	yield(get_tree(), "idle_frame")
	editor_view.refresh()


func _on_export_csv_pressed():
	hide()
	var exported_cols = editor_view.columns.duplicate()
	exported_cols.erase("resource_local_to_scene")
	for x in editor_view.hidden_columns[editor_view.current_path].keys():
		exported_cols.erase(x)

	SpreadsheetExportFormatCsv.export_to_file(editor_view.rows, exported_cols, import_data.edited_path, import_data)
	yield(get_tree(), "idle_frame")
	editor_view.refresh()


# Input controls
func _on_classname_field_text_changed(new_text : String):
	import_data.script_classname = new_text.replace(" ", "")


func _on_remove_first_row_toggled(button_pressed : bool):
	import_data.remove_first_row = button_pressed
	$"TabContainer/Export/HBoxContainer2/Button".pressed = true
	$"TabContainer/Export/HBoxContainer3/CheckBox".pressed = true


func _on_filename_options_item_selected(index):
	property_used_as_filename = index


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


func _reset_controls():
	$"TabContainer/Export/HBoxContainer2/CheckBox".pressed = false
	_on_remove_first_row_toggled(true)


func _on_enum_format_changed(case, delimiter, bool_yes, bool_no):
	import_data.enum_format = [case, delimiter, bool_yes, bool_no]
