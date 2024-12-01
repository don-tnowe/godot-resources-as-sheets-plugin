@tool
extends Control

signal grid_updated()

const TablesPluginSettingsClass := preload("res://addons/resources_spreadsheet_view/settings_grid.gd")

@onready var node_folder_path : LineEdit = $"HeaderContentSplit/VBoxContainer/HBoxContainer/HBoxContainer/Path"
@onready var node_recent_paths : OptionButton = $"HeaderContentSplit/VBoxContainer/HBoxContainer/HBoxContainer2/RecentPaths"
@onready var node_table_root : GridContainer = $"HeaderContentSplit/MarginContainer/FooterContentSplit/Panel/Scroll/MarginContainer/TableGrid"
@onready var node_columns : HBoxContainer = $"HeaderContentSplit/VBoxContainer/Columns/Columns"
@onready var node_page_manager : Control = $"HeaderContentSplit/VBoxContainer/HBoxContainer3/Pages"
@onready var node_class_filter : Control = $"HeaderContentSplit/VBoxContainer/Search/Search/Class"

@onready var _on_cell_gui_input : Callable = $"InputHandler"._on_cell_gui_input
@onready var _selection := $"SelectionManager"

var editor_interface : Object
var editor_plugin : EditorPlugin

var current_path := ""
var save_data_path : String = get_script().resource_path.get_base_dir() + "/saved_state.json"
var sorting_by := &""
var sorting_reverse := false

var columns : Array[StringName] = []
var column_types : Array[int] = []
var column_hints : Array[int] = []
var column_hint_strings : Array[PackedStringArray] = []
var rows := []
var remembered_paths := {}
var remembered_paths_total_count := 0
var table_functions_dict := {}

var search_cond : Callable
var io : RefCounted

var first_row := 0
var last_row := 0


func _ready():
	editor_interface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed)
	if FileAccess.file_exists(save_data_path):
		var file := FileAccess.open(save_data_path, FileAccess.READ)
		var as_text := file.get_as_text()
		var as_var := JSON.parse_string(as_text)

		node_recent_paths.load_paths(as_var.get(&"recent_paths", []))
		node_columns.hidden_columns = as_var.get(&"hidden_columns", {})
		table_functions_dict = as_var.get(&"table_functions", {})
		for x in $"HeaderContentSplit/VBoxContainer/Search/Search".get_children():
			if x.has_method(&"load_saved_functions"):
				x.load_saved_functions(table_functions_dict)

	if node_recent_paths.recent_paths.size() >= 1:
		display_folder(node_recent_paths.recent_paths[-1], &"resource_name", false, true)


func save_data():
	var file := FileAccess.open(save_data_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(
		{
			&"recent_paths" : node_recent_paths.recent_paths,
			&"hidden_columns" : node_columns.hidden_columns,
			&"table_functions" : table_functions_dict,
		}
	, "  "))


func _on_filesystem_changed():
	if current_path == "":
		return

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


func display_folder(folderpath : String, sort_by : StringName = "", sort_reverse : bool = false, force_rebuild : bool = false, is_echo : bool = false):
	if folderpath == "":
		# You wouldn't just wanna edit ALL resources in the project, that's a long time to load!
		return

	if sort_by == "":
		sort_by = &"resource_path"

	if folderpath.get_extension() == "":
		folderpath = folderpath.trim_suffix("/") + "/"

	if folderpath.ends_with(".tres") and !folderpath.ends_with(ResourceTablesImport.SUFFIX):
		folderpath = folderpath.get_base_dir() + "/"

	node_recent_paths.add_path_to_recent(folderpath)
	node_folder_path.text = folderpath

	_load_resources_from_path(folderpath, sort_by, sort_reverse)
	_update_visible_rows(force_rebuild or current_path != folderpath)

	current_path = folderpath
	remembered_paths_total_count = _get_file_count_recursive(folderpath)
	node_columns.update()
	grid_updated.emit()

	$"HeaderContentSplit/MarginContainer/FooterContentSplit/Panel/Label".visible = rows.size() == 0
	$"HeaderContentSplit/MarginContainer/FooterContentSplit/Panel/Label".text = "No rows visible?\nThis might happen when sorting by a property that isn't here anymore.\nTry clicking a column header to sort again!\n\nIt's also possible that your Filter expression is filtering them out."


func display_resources(resource_array : Array):
	if sorting_by == "":
		sorting_by = &"resource_path"

	current_path = ""
	node_recent_paths.select(-1)
	rows = []
	for x in resource_array:
		insert_row_sorted(x, rows, sorting_by, sorting_reverse)

	fill_property_data_many(rows)
	_update_visible_rows()

	node_columns.update()
	grid_updated.emit()


func refresh(force_rebuild : bool = true):
	if current_path == "":
		display_resources(rows)

	else:
		display_folder(current_path, sorting_by, sorting_reverse, force_rebuild)


func _load_resources_from_path(path : String, sort_by : StringName, sort_reverse : bool):
	if path.ends_with("/"):
		io = ResourceTablesEditFormatTres.new()

	else:
		var loaded := load(path)
		if loaded is ResourceTablesImport:
			io = loaded.view_script.new()
			node_class_filter.hide()

		else:
			io = ResourceTablesEditFormatTres.new()
	
	io.editor_view = self
	remembered_paths.clear()
	rows = io.import_from_path(path, insert_row_sorted, sort_by, sort_reverse)


func _update_visible_rows(force_rebuild : bool = true):
	node_page_manager.update_page_count(rows)
	if columns.size() == 0:
		return

	if force_rebuild or columns != node_columns.columns:
		for x in node_table_root.get_children():
			x.free()

		node_columns.columns = columns

	var cells_left_to_free : int = node_table_root.get_child_count() - (last_row - first_row) * columns.size()
	while cells_left_to_free > 0:
		node_table_root.get_child(0).free()
		cells_left_to_free -= 1
	
	var color_rows : bool = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "color_rows")
	for i in last_row - first_row:
		_update_row(first_row + i, color_rows)


func fill_property_data(res : Resource):
	columns.clear()
	column_types.clear()
	column_hints.clear()
	column_hint_strings.clear()
	var column_values := []
	var i := -1
	for x in res.get_property_list():
		if x[&"usage"] & PROPERTY_USAGE_EDITOR != 0 and x[&"name"] != "script":
			i += 1
			columns.append(x[&"name"])
			column_types.append(x[&"type"])
			column_hints.append(x[&"hint"])
			column_hint_strings.append(x[&"hint_string"].split(","))
			column_values.append(io.get_value(res, columns[i]))

	_selection.initialize_editors(column_values, column_types, column_hints)


func fill_property_data_many(resources : Array):
	node_class_filter.fill(resources)

	columns.clear()
	column_types.clear()
	column_hints.clear()
	column_hint_strings.clear()
	var column_values := []
	var i := -1
	var found_props := {}
	for x in resources:
		if x == null: continue
		i += 1
		if not search_cond.is_null() and not search_cond.call(x, i):
			continue

		if not node_class_filter.filter(x):
			continue

		for y in x.get_property_list():
			found_props[y[&"name"]] = y
			y[&"owner_object"] = x

	i = -1
	for x in found_props.values():
		if x[&"usage"] & PROPERTY_USAGE_EDITOR != 0 and x[&"name"] != "script":
			i += 1
			columns.append(x[&"name"])
			column_types.append(x[&"type"])
			column_hints.append(x[&"hint"])
			column_hint_strings.append(x[&"hint_string"].split(","))
			column_values.append(io.get_value(x[&"owner_object"], columns[i]))

	_selection.initialize_editors(column_values, column_types, column_hints)


func insert_row_sorted(res : Resource, loaded_rows : Array, sort_by : StringName, sort_reverse : bool):
	if not search_cond.is_null() and not search_cond.call(res, loaded_rows.size()):
		return

	if not sort_by in res or not node_class_filter.filter(res):
		return

	var sort_value = res[sort_by]
	for i in loaded_rows.size():
		if sort_reverse == compare_values(sort_value, loaded_rows[i][sort_by]):
			loaded_rows.insert(i, res)
			return
	
	remembered_paths[res.resource_path] = res
	loaded_rows.append(res)


func compare_values(a, b) -> bool:
	if a == null or b == null: return b == null
	if a is Color:
		return a.h > b.h if a.h != b.h else a.v > b.v

	if a is Resource:
		return a.resource_path > b.resource_path
	
	if a is Array:
		return a.size() > b.size()
		
	return a > b


func column_can_solo_open(column_index : int) -> bool:
	return (
		column_types[column_index] == TYPE_OBJECT
		or (column_types[column_index] == TYPE_ARRAY and column_hint_strings[column_index][0].begins_with("24"))
	)


func column_solo_open(column_index : int):
	display_folder(current_path.trim_suffix("/") + "::" + columns[column_index])


func _set_sorting(sort_by : StringName):
	var sort_reverse : bool = !(sorting_by != sort_by or sorting_reverse)
	sorting_reverse = sort_reverse
	sorting_by = sort_by
	refresh()


func _update_row(row_index : int, color_rows : bool = true):
	var current_node : Control
	var next_color := Color.WHITE
	var column_editors : Array = _selection.column_editors
	var shortened_path : String = rows[row_index].resource_path.get_file().trim_suffix(".tres")
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
				+ "Of " + shortened_path
			)

		if columns[i] in rows[row_index]:
			current_node.mouse_filter = MOUSE_FILTER_STOP
			current_node.modulate.a = 1.0

		else:
			# Empty cell, can't click, property doesn't exist.
			current_node.mouse_filter = MOUSE_FILTER_IGNORE
			current_node.modulate.a = 0.0
			continue

		if columns[i] == &"resource_path":
			column_editors[i].set_value(current_node, shortened_path)

		else:			
			var cell_value = io.get_value(rows[row_index], columns[i])
			if cell_value != null or column_types[i] == TYPE_OBJECT:
				column_editors[i].set_value(current_node, cell_value)
				if color_rows and column_types[i] == TYPE_COLOR:
					next_color = cell_value

		column_editors[i].set_color(current_node, next_color)


func get_selected_column() -> int:
	return _selection.get_cell_column(_selection.edited_cells[0])


func select_column(column_index : int):
	_selection.deselect_all_cells()
	_selection.select_cell(Vector2i(column_index, 0))
	_selection.select_cells_to(Vector2i(column_index, rows.size() - 1))


func set_edited_cells_values_text(new_cell_values : Array):
	var column_editor : Object = _selection.column_editors[get_selected_column()]

	# Duplicated here since if using text editing, edited_cells_text needs to modified
	# but here, it would be converted from a String breaking editing
	var new_cell_values_converted := new_cell_values.duplicate()
	for i in new_cell_values.size():
		new_cell_values_converted[i] = column_editor.from_text(new_cell_values[i])

	set_edited_cells_values(new_cell_values_converted)
	for i in new_cell_values.size():
		var i_pos : Vector2i = _selection.edited_cells[i]
		var update_cell : Control = _selection.get_cell_node_from_position(i_pos)
		if update_cell == null:
			continue

		column_editor.set_value(update_cell, new_cell_values[i])


func set_edited_cells_values(new_cell_values : Array):
	var edited_rows : Array = _selection.get_edited_rows()
	var column : int = _selection.get_cell_column(_selection.edited_cells[0])
	var edited_cells_resources := _get_row_resources(edited_rows)

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
	_selection._update_selected_cells_text()


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
	var column_index : int = _selection.get_cell_column(cells[0])
	var result := []
	result.resize(cells.size())
	for i in cells.size():
		result[i] = io.get_value(rows[_selection.get_cell_row(cells[i])], columns[column_index])
	
	return result


func _update_resources(update_rows : Array, update_row_indices : Array[int], update_column : int, values : Array):
	var column_editor : Object = _selection.column_editors[update_column]
	for i in update_rows.size():
		var row := update_row_indices[i]
		io.set_value(
			update_rows[i],
			columns[update_column],
			values[i],
			row
		)
		var update_cell : Control = _selection.get_cell_node_from_position(Vector2i(update_column, row))
		if update_cell == null:
			continue

		column_editor.set_value(update_cell, values[i])
		var row_script : Object = update_rows[i].get_script()
		if row_script != null && row_script.is_tool():
			for column_i in columns.size():
				if column_i == update_column:
					continue

				var update_cell_c : Control = _selection.get_cell_node_from_position(Vector2i(column_i, row))
				_selection.column_editors[column_i].set_value(update_cell_c, update_rows[i].get(columns[column_i]))

		if values[i] == null:
			continue

		if column_types[update_column] == TYPE_COLOR:
			for j in columns.size() - update_column:
				if j != 0 and column_types[j + update_column] == TYPE_COLOR:
					break

				_selection.column_editors[j + update_column].set_color(
					_selection.get_cell_node_from_position(Vector2i(update_column + j, row)),
					values[i]
				)

	node_columns._update_column_sizes()
	io.save_entries(rows, update_row_indices)


func _on_path_text_submitted(new_text : String = ""):
	if new_text != "":
		current_path = new_text
		display_folder(new_text, "", false, true)

	else:
		refresh()


func _on_FileDialog_dir_selected(dir : String):
	node_folder_path.text = dir
	display_folder(dir)


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
