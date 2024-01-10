@tool
extends Control

signal grid_updated()

const TablesPluginSettingsClass := preload("res://addons/resources_spreadsheet_view/settings_grid.gd")

@export @onready var node_folder_path : LineEdit = $"HeaderContentSplit/VBoxContainer/HBoxContainer/HBoxContainer/Path"
@export @onready var node_recent_paths : OptionButton = $"HeaderContentSplit/VBoxContainer/HBoxContainer/HBoxContainer2/RecentPaths"
@export @onready var node_table_root : GridContainer = $"HeaderContentSplit/MarginContainer/FooterContentSplit/Panel/Scroll/MarginContainer/TableGrid"
@export @onready var node_columns : HBoxContainer = $"HeaderContentSplit/VBoxContainer/Columns/Columns"
@export @onready var node_page_manager : Control = $"HeaderContentSplit/VBoxContainer/HBoxContainer3/Pages"

@onready var _on_cell_gui_input : Callable = $"InputHandler"._on_cell_gui_input
@onready var _selection := $"SelectionManager"

var editor_interface : Object
var editor_plugin : EditorPlugin

var current_path := ""
var save_data_path : String = get_script().resource_path.get_base_dir() + "/saved_state.json"
var sorting_by := ""
var sorting_reverse := false

var columns := []
var column_types := []
var column_hints := []
var column_hint_strings := []
var rows := []
var remembered_paths := {}
var remembered_paths_total_count := 0
var table_functions_dict := {}

var search_cond : RefCounted
var io : RefCounted

var first_row := 0
var last_row := 0


func _ready():
	editor_interface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed)
	if FileAccess.file_exists(save_data_path):
		var file = FileAccess.open(save_data_path, FileAccess.READ)
		var as_text = file.get_as_text()
		var as_var = JSON.parse_string(as_text)

		node_recent_paths.load_paths(as_var.get("recent_paths", []))
		node_columns.hidden_columns = as_var.get("hidden_columns", {})
		table_functions_dict = as_var.get("table_functions", {})
		for x in $"HeaderContentSplit/VBoxContainer/Search/Search".get_children():
			if x.has_method(&"load_saved_functions"):
				x.load_saved_functions(table_functions_dict)

	if node_recent_paths.recent_paths.size() >= 1:
		display_folder(node_recent_paths.recent_paths[0], "resource_name", false, true)


func _on_filesystem_changed():
	var file_total_count := _get_file_count_recursive(current_path)
	if file_total_count != remembered_paths_total_count:
		refresh()

	else:
		for k in remembered_paths:
			if !is_instance_valid(remembered_paths[k]):
				continue

			if remembered_paths[k].resource_path != k:
				var res = remembered_paths[k]
				remembered_paths.erase(k)
				remembered_paths[res.resource_path] = res
				refresh()
				break


func _get_file_count_recursive(path : String) -> int:
	var editor_fs : EditorFileSystem = editor_interface.get_resource_filesystem()
	var path_dir := editor_fs.get_filesystem_path(path)
	if !path_dir: return 0

	var file_total_count := 0
	var folder_stack : Array[EditorFileSystemDirectory] = [path_dir]
	while folder_stack.size() > 0:
		path_dir = folder_stack.pop_back()
		file_total_count += path_dir.get_file_count()
		for i in path_dir.get_subdir_count():
			folder_stack.append(path_dir.get_subdir(i))

	return file_total_count


func display_folder(folderpath : String, sort_by : String = "", sort_reverse : bool = false, force_rebuild : bool = false, is_echo : bool = false):
	if folderpath == "": return  # Root folder resources tend to have MANY properties.
	$"HeaderContentSplit/MarginContainer/FooterContentSplit/Panel/Label".visible = false
	if folderpath.get_extension() == "":
		folderpath = folderpath.trim_suffix("/") + "/"

	if folderpath.ends_with(".tres") and !folderpath.ends_with(ResourceTablesImport.SUFFIX):
		folderpath = folderpath.get_base_dir() + "/"

	node_recent_paths.add_path_to_recent(folderpath)
	first_row = node_page_manager.first_row
	_load_resources_from_path(folderpath, sort_by, sort_reverse)
	last_row = min(first_row + node_page_manager.rows_per_page, rows.size())

	if columns.size() == 0: return

	node_folder_path.text = folderpath
	_update_table(
		force_rebuild
		or current_path != folderpath
		or columns.size() != node_columns.get_child_count()
	)
	current_path = folderpath
	remembered_paths_total_count = _get_file_count_recursive(folderpath)
	node_columns.update()
	grid_updated.emit()


func refresh(force_rebuild : bool = true):
	display_folder(current_path, sorting_by, sorting_reverse, force_rebuild)


func _load_resources_from_path(path : String, sort_by : String, sort_reverse : bool):
	if path.ends_with("/"):
		io = ResourceTablesEditFormatTres.new()

	else:
		var loaded = load(path)
		if loaded is ResourceTablesImport:
			io = loaded.view_script.new()

		else:
			io = ResourceTablesEditFormatTres.new()
	
	io.editor_view = self
	remembered_paths.clear()
	rows = io.import_from_path(path, insert_row_sorted, sort_by, sort_reverse)


func fill_property_data(res):
	columns.clear()
	column_types.clear()
	column_hints.clear()
	column_hint_strings.clear()
	var column_values := []
	var i := -1
	for x in res.get_property_list():
		if x["usage"] & PROPERTY_USAGE_EDITOR != 0 and x["name"] != "script":
			i += 1
			columns.append(x["name"])
			column_types.append(x["type"])
			column_hints.append(x["hint"])
			column_hint_strings.append(x["hint_string"].split(","))
			column_values.append(io.get_value(res, columns[i]))

	_selection.initialize_editors(column_values, column_types, column_hints)


func insert_row_sorted(res : Resource, rows : Array, sort_by : String, sort_reverse : bool):
	if search_cond != null and !search_cond.can_show(res, rows.size()):
		return
		
	for i in rows.size():
		if sort_reverse == compare_values(io.get_value(res, sort_by), io.get_value(rows[i], sort_by)):
			rows.insert(i, res)
			return
	
	remembered_paths[res.resource_path] = res
	rows.append(res)


func compare_values(a, b) -> bool:
	if a == null or b == null: return b == null
	if a is Color:
		return a.h > b.h if a.h != b.h else a.v > b.v

	if a is Resource:
		return a.resource_path > b.resource_path
	
	if a is Array:
		return a.size() > b.size()
		
	return a > b


func _set_sorting(sort_by):
	var sort_reverse : bool = !(sorting_by != sort_by or sorting_reverse)
	sorting_reverse = sort_reverse
	display_folder(current_path, sort_by, sort_reverse)
	sorting_by = sort_by


func _update_table(columns_changed : bool):
	if columns_changed:
		node_table_root.columns = columns.size()
		for x in node_table_root.get_children():
			x.free()

		node_columns.columns = columns

	var to_free = node_table_root.get_child_count() - (last_row - first_row) * columns.size()
	while to_free > 0:
		node_table_root.get_child(0).free()
		to_free -= 1
	
	var color_rows = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "color_rows")
	
	_update_row_range(
		first_row,
		last_row,
		color_rows
	)


func _update_row_range(first : int, last : int, color_rows : bool):
	for i in last - first:
		_update_row(first + i, color_rows)


func _update_row(row_index : int, color_rows : bool = true):
	var current_node : Control
	var next_color := Color.WHITE
	var column_editors : Array = _selection.column_editors
	var res_path : String = rows[row_index].resource_path.get_basename().substr(current_path.length())
	for i in columns.size():
		if node_table_root.get_child_count() <= (row_index - first_row) * columns.size() + i:
			current_node = column_editors[i].create_cell(self)
			current_node.gui_input.connect(_on_cell_gui_input.bind(current_node))
			node_table_root.add_child(current_node)

		else:
			current_node = node_table_root.get_child((row_index - first_row) * columns.size() + i)
			current_node.tooltip_text = (
				columns[i].capitalize()
				+ "\n---\n"
				+ "Of " + res_path
			)
		
		column_editors[i].set_value(current_node, io.get_value(rows[row_index], columns[i]))
		if columns[i] == "resource_path":
			column_editors[i].set_value(current_node, res_path)

		if color_rows and column_types[i] == TYPE_COLOR:
			next_color = io.get_value(rows[row_index], columns[i])

		column_editors[i].set_color(current_node, next_color)


func save_data():
	var file = FileAccess.open(save_data_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(
		{
			"recent_paths" : node_recent_paths.recent_paths,
			"hidden_columns" : node_columns.hidden_columns,
			"table_functions" : table_functions_dict,
		}
	, "  "))


func _on_path_text_submitted(new_text : String = ""):
	if new_text != "":
		current_path = new_text
		display_folder(new_text, "", false, true)

	else:
		refresh()


func _on_FileDialog_dir_selected(dir : String):
	node_folder_path.text = dir
	display_folder(dir)


func get_selected_column() -> int:
	return _selection.get_cell_column(_selection.edited_cells[0])


func select_column(column_index : int):
	_selection.deselect_all_cells()
	_selection.select_cell(node_table_root.get_child(column_index))
	_selection.select_cells_to(node_table_root.get_child(
		column_index + columns.size()
		* (last_row - first_row - 1))
	)


func set_edited_cells_values(new_cell_values : Array):
	var edited_rows = _selection.get_edited_rows()
	var column = _selection.get_cell_column(_selection.edited_cells[0])
	var edited_cells_resources = _get_row_resources(edited_rows)

	# Duplicated here since if using text editing, edited_cells_text needs to modified
	# but here, it would be converted from a String breaking editing
	new_cell_values = new_cell_values.duplicate()

	editor_plugin.undo_redo.create_action("Set Cell Values")
	editor_plugin.undo_redo.add_undo_method(
		self,
		&"_update_resources",
		edited_cells_resources.duplicate(),
		edited_rows.duplicate(),
		column,
		get_edited_cells_values()
	)
	editor_plugin.undo_redo.add_undo_method(
		_selection,
		&"_update_selected_cells_text"
	)
	editor_plugin.undo_redo.add_do_method(
		self,
		&"_update_resources",
		edited_cells_resources.duplicate(),
		edited_rows.duplicate(),
		column,
		new_cell_values.duplicate()
	)
	editor_plugin.undo_redo.commit_action(true)
	# editor_interface.get_resource_filesystem().scan()


func rename_row(row, new_name):
	if !has_row_names(): return
		
	io.rename_row(row, new_name)
	refresh()


func duplicate_selected_rows(new_name : String):
	io.duplicate_rows(_get_row_resources(_selection.get_edited_rows()), new_name)
	refresh()


func delete_selected_rows():
	io.delete_rows(_get_row_resources(_selection.get_edited_rows()))
	refresh()
	refresh.call_deferred()


func has_row_names():
	return io.has_row_names()


func get_last_selected_row():
	return rows[_selection.get_cell_row(_selection.edited_cells[-1])]


func get_edited_cells_values() -> Array:
	var cells : Array = _selection.edited_cells.duplicate()
	var column_index : int = _selection.get_cell_column(_selection.edited_cells[0])
	var cell_editor : Object = _selection.column_editors[column_index]

	var result := []
	result.resize(cells.size())
	for i in cells.size():
		result[i] = io.get_value(rows[_selection.get_cell_row(cells[i])], columns[column_index])
	
	return result


func _update_resources(update_rows : Array, update_row_indices : Array[int], update_column : int, values : Array):
	var column_editor = _selection.column_editors[update_column]
	for i in update_rows.size():
		var row = update_row_indices[i]
		var update_cell = node_table_root.get_child((row - first_row) * columns.size() + update_column)

		column_editor.set_value(update_cell, values[i])
		if values[i] is String:
			values[i] = try_convert(values[i], column_types[update_column])

		if values[i] == null:
			continue
		
		io.set_value(
			update_rows[i],
			columns[update_column],
			values[i],
			row
		)
		continue
		if column_types[update_column] == TYPE_COLOR:
			for j in columns.size() - update_column:
				if j != 0 and column_types[j + update_column] == TYPE_COLOR:
					break

				_selection.column_editors[j + update_column].set_color(
					update_cell.get_parent().get_child(
						row * columns.size() + update_column + j - first_row
					),
					values[i]
				)

	node_columns._update_column_sizes()
	io.save_entries(rows, update_row_indices)


func try_convert(value, type):
	if type == TYPE_BOOL:
		# "off" displayed in lowercase, "ON" in uppercase.
		return value[0] == "o"

	# If it can't convert, throws exception and returns null.
	return convert(value, type)


func _get_row_resources(row_indices) -> Array:
	var arr := []
	arr.resize(row_indices.size())
	for i in arr.size():
		arr[i] = rows[row_indices[i]]

	return arr


func _on_File_pressed():
	node_folder_path.get_parent().get_parent().visible = !node_folder_path.get_parent().get_parent().visible


func _on_SearchProcess_pressed():
	$"HeaderContentSplit/VBoxContainer/Search".visible = !$"HeaderContentSplit/VBoxContainer/Search".visible
