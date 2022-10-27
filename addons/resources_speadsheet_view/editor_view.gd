tool
extends Control

signal grid_updated()
signal cells_selected(cells)
signal cells_context(cells)

export var table_header_scene : PackedScene

export(Array, Script) var cell_editor_classes := []

export var path_folder_path := NodePath("")
export var path_recent_paths := NodePath("")
export var path_table_root := NodePath("")
export var path_property_editors := NodePath("")
export var path_columns := NodePath("")
export var path_hide_columns_button := NodePath("")
export var path_page_manager := NodePath("")

var editor_interface : EditorInterface
var editor_plugin : EditorPlugin

var current_path := ""
var recent_paths := []
var save_data_path : String = get_script().resource_path.get_base_dir() + "/saved_state.json"
var sorting_by := ""
var sorting_reverse := false
var undo_redo_version := 0

var all_cell_editors := []

var columns := []
var column_types := []
var column_hints := []
var column_hint_strings := []
var column_editors := []
var rows := []
var remembered_paths := {}

var edited_cells := []
var edited_cells_text := []
var edit_cursor_positions := []
var inspector_resource : Resource
var search_cond : Reference
var io : Reference

var hidden_columns := {}
var first_row := 0
var last_row := 0


func _ready():
	get_node(path_recent_paths).clear()
	editor_interface.get_resource_filesystem()\
		.connect("filesystem_changed", self, "_on_filesystem_changed")
	editor_interface.get_inspector()\
		.connect("property_edited", self, "_on_inspector_property_edited")
	get_node(path_hide_columns_button).get_popup()\
		.connect("id_pressed", self, "_on_VisibleCols_id_pressed")

	# Load saved recent paths
	var file := File.new()
	if file.file_exists(save_data_path):
		file.open(save_data_path, File.READ)

		var as_text = file.get_as_text()
		var as_var = str2var(as_text)
		for x in as_var["recent_paths"]:
			add_path_to_recent(x, true)

		hidden_columns = as_var["hidden_columns"]

	# Load cell editors and instantiate them
	for x in cell_editor_classes:
		all_cell_editors.append(x.new())
		all_cell_editors[all_cell_editors.size() - 1].hint_strings_array = column_hint_strings
	
	get_node(path_recent_paths).selected = 0
	display_folder(recent_paths[0], "resource_name", false, true)


func _on_filesystem_changed():
	var path = editor_interface.get_resource_filesystem().get_filesystem_path(current_path)
	if !path: return
	if path.get_file_count() != remembered_paths.size():
		refresh()

	else:
		for k in remembered_paths:
			if remembered_paths[k].resource_path != k:
				var res = remembered_paths[k]
				remembered_paths.erase(k)
				remembered_paths[res.resource_path] = res
				refresh()
				break


func display_folder(folderpath : String, sort_by : String = "", sort_reverse : bool = false, force_rebuild : bool = false, is_echo : bool = false):
	if folderpath == "": return  # Root folder resources tend to have MANY properties.W
	$"HeaderContentSplit/MarginContainer/FooterContentSplit/Panel/Label".visible = false
	if folderpath.get_extension() == "":
		folderpath = folderpath.trim_suffix("/") + "/"

	if folderpath.ends_with(".tres") and !folderpath.ends_with(SpreadsheetImport.SUFFIX):
		folderpath = folderpath.get_base_dir() + "/"
	
	if search_cond == null:
		_on_SearchCond_text_entered("true")

	add_path_to_recent(folderpath)
	_load_resources_from_folder(folderpath, sort_by, sort_reverse)
	first_row = get_node(path_page_manager).first_row
	last_row = min(get_node(path_page_manager).last_row, rows.size())
	if columns.size() == 0: return

	get_node(path_folder_path).text = folderpath
	_create_table(
		force_rebuild
		or current_path != folderpath
		or columns.size() != get_node(path_columns).get_child_count()
	)
	current_path = folderpath
	_update_hidden_columns()
	_update_column_sizes()
	
	if is_echo: return
	yield(get_tree().create_timer(0.25), "timeout")
	if get_node(path_table_root).get_child_count() == 0:
		display_folder(folderpath, sort_by, sort_reverse, force_rebuild, true)

	else:
		emit_signal("grid_updated")


func refresh(force_rebuild : bool = true):
	display_folder(current_path, sorting_by, sorting_reverse, force_rebuild)


func _load_resources_from_folder(path : String, sort_by : String, sort_reverse : bool):
	if path.ends_with("/"):
		io = SpreadsheetEditFormatTres.new()

	else:
		io = load(path).view_script.new()
	
	io.editor_view = self
	rows = io.import_from_path(path, funcref(self, "insert_row_sorted"), sort_by, sort_reverse)


func fill_property_data(res):
	columns.clear()
	column_types.clear()
	column_hints.clear()
	column_hint_strings.clear()
	column_editors.clear()
	var column_index = -1
	for x in res.get_property_list():
		if x["usage"] & PROPERTY_USAGE_EDITOR != 0 and x["name"] != "script":
			column_index += 1
			columns.append(x["name"])
			column_types.append(x["type"])
			column_hints.append(x["hint"])
			column_hint_strings.append(x["hint_string"].split(","))
			for y in all_cell_editors:
				if y.can_edit_value(io.get_value(res, x["name"]), x["type"], x["hint"], column_index):
					column_editors.append(y)
					break


func insert_row_sorted(res : Resource, rows : Array, sort_by : String, sort_reverse : bool):
	if !search_cond.can_show(res, rows.size()):
		return
		
	for i in rows.size():
		if sort_reverse == compare_values(io.get_value(res, sort_by), io.get_value(rows[i], sort_by)):
			rows.insert(i, res)
			return
	
	rows.append(res)


func compare_values(a, b) -> bool:
	if a == null or b == null: return b == null
	if a is Color:
		return a.h > b.h if a.h != b.h else a.v > b.v

	if a is Resource:
		return a.resource_path > b.resource_path
	
	if a is Array or a is PoolStringArray or a is PoolRealArray or a is PoolIntArray:
		return a.size() > b.size()
		
	return a > b


func _set_sorting(sort_by):
	var sort_reverse : bool = !(sorting_by != sort_by or sorting_reverse)
	sorting_reverse = sort_reverse
	display_folder(current_path, sort_by, sort_reverse)
	sorting_by = sort_by


func _create_table(columns_changed : bool):
	var root_node = get_node(path_table_root)
	var headers_node = get_node(path_columns)
	deselect_all_cells()
	edited_cells = []
	edited_cells_text = []
	edit_cursor_positions = []
	var new_node : Control
	if columns_changed:
		root_node.columns = columns.size()
		for x in root_node.get_children():
			x.free()
		
		for x in headers_node.get_children():
			x.queue_free()

		for x in columns:
			new_node = table_header_scene.instance()
			headers_node.add_child(new_node)
			new_node.editor_view = self
			new_node.set_label(x)
			new_node.get_node("Button").connect("pressed", self, "_set_sorting", [x])
	
	var to_free = root_node.get_child_count() - (last_row - first_row) * columns.size()
	while to_free > 0:
		root_node.get_child(0).free()
		to_free -= 1
	
	var color_rows = ProjectSettings.get_setting(SettingsGrid.SETTING_PREFIX + "color_rows")
	
	_update_row_range(
		first_row,
		last_row,
		color_rows
	)


func _update_row_range(first : int, last : int, color_rows : bool):
	for i in last - first:
		_update_row(first + i, color_rows)


func _update_column_sizes():
	yield(get_tree(), "idle_frame")
	var table_root := get_node(path_table_root)
	var column_headers := get_node(path_columns).get_children()

	if table_root.get_child_count() < column_headers.size(): return
	if column_headers.size() != columns.size():
		refresh()
		return

	var clip_text : bool = ProjectSettings.get_setting(SettingsGrid.SETTING_PREFIX + "clip_headers")
	var min_width := 0
	var cell : Control

	get_node(path_columns).get_parent().rect_min_size.y = column_headers[0].rect_size.y
	for i in column_headers.size():
		cell = table_root.get_child(i)

		column_headers[i].get_child(0).clip_text = clip_text
		column_headers[i].rect_min_size.x = 0
		cell.rect_min_size.x = 0
		column_headers[i].rect_size.x = 0

		min_width = max(column_headers[i].rect_size.x, cell.rect_size.x)
		column_headers[i].rect_min_size.x = min_width
		cell.rect_min_size.x = column_headers[i].get_minimum_size().x
		column_headers[i].rect_size.x = min_width

	yield(get_tree(), "idle_frame")
	for i in column_headers.size():
		column_headers[i].rect_position.x = table_root.get_child(i).rect_position.x
		

func _update_row(row_index : int, color_rows : bool = true):
	var root_node = get_node(path_table_root)
	var current_node : Control
	var next_color := Color.white
	for i in columns.size():
		if root_node.get_child_count() <= (row_index - first_row) * columns.size() + i:
			current_node = column_editors[i].create_cell(self)
			current_node.connect("gui_input", self, "_on_cell_gui_input", [current_node])
			root_node.add_child(current_node)

		else:
			current_node = root_node.get_child((row_index - first_row) * columns.size() + i)
			current_node.hint_tooltip = (
				TextEditingUtils.string_snake_to_naming_case(columns[i])
				+ "\n---\n"
				+ "Of " + rows[row_index].resource_path.get_file().get_basename()
			)
		
		column_editors[i].set_value(current_node, io.get_value(rows[row_index], columns[i]))
		if columns[i] == "resource_path":
			column_editors[i].set_value(current_node, current_node.text.get_file().get_basename())

		if color_rows and column_types[i] == TYPE_COLOR:
			next_color = io.get_value(rows[row_index], columns[i])

		column_editors[i].set_color(current_node, next_color)


func _update_hidden_columns():
	if !hidden_columns.has(current_path):
		hidden_columns[current_path] = {}
		return

	var node_table_root = get_node(path_table_root)
	var visible_column_count = 0
	for i in columns.size():
		var column_visible = !hidden_columns[current_path].has(columns[i])

		get_node(path_columns).get_child(i).visible = column_visible
		for j in last_row - first_row:
			node_table_root.get_child(j * columns.size() + i).visible = column_visible

		if column_visible:
			visible_column_count += 1

	node_table_root.columns = visible_column_count


func add_path_to_recent(path : String, is_loading : bool = false):
	if path in recent_paths: return

	var node_recent := get_node(path_recent_paths)
	var idx_in_array := recent_paths.find(path)
	if idx_in_array != -1:
		node_recent.remove_item(idx_in_array)
		recent_paths.remove(idx_in_array)
	
	recent_paths.append(path)
	node_recent.add_item(path)
	node_recent.select(node_recent.get_item_count() - 1)

	if !is_loading:
		save_data()


func remove_selected_path_from_recent():
	if get_node(path_recent_paths).get_item_count() == 0:
		return
	
	var idx_in_array = get_node(path_recent_paths).selected
	recent_paths.remove(idx_in_array)
	get_node(path_recent_paths).remove_item(idx_in_array)

	if get_node(path_recent_paths).get_item_count() != 0:
		get_node(path_recent_paths).select(0)
		display_folder(recent_paths[0])
		save_data()


func save_data():
	var file = File.new()
	file.open(save_data_path, File.WRITE)
	file.store_string(var2str(
		{
			"recent_paths" : recent_paths,
			"hidden_columns" : hidden_columns,
		}
	))


func _on_Path_text_entered(new_text : String = ""):
	if new_text != "":
		current_path = new_text
		display_folder(new_text, "", false, true)

	else:
		refresh()


func _on_RecentPaths_item_selected(index : int):
	current_path = recent_paths[index]
	get_node(path_folder_path).text = recent_paths[index]
	display_folder(current_path, sorting_by, sorting_reverse, true)


func _on_FileDialog_dir_selected(path : String):
	get_node(path_folder_path).text = path
	display_folder(path)


func deselect_all_cells():
	for x in edited_cells:
		column_editors[_get_cell_column(x)].set_selected(x, false)

	edited_cells.clear()
	edited_cells_text.clear()
	edit_cursor_positions.clear()
	emit_signal("cells_selected", [])


func deselect_cell(cell : Control):
	var idx := edited_cells.find(cell)
	if idx == -1: return

	column_editors[_get_cell_column(cell)].set_selected(cell, false)
	edited_cells.remove(idx)
	if edited_cells_text.size() != 0:
		edited_cells_text.remove(idx)
		edit_cursor_positions.remove(idx)
		
	emit_signal("cells_selected", edited_cells)


func select_cell(cell : Control):
	var column_index := _get_cell_column(cell)
	if _can_select_cell(cell):
		_add_cell_to_selection(cell)
		_try_open_docks(cell)
		inspector_resource = rows[_get_cell_row(cell)].duplicate()
		editor_plugin.get_editor_interface().edit_resource(inspector_resource)

	emit_signal("cells_selected", edited_cells)


func select_cells_to(cell : Control):
	var column_index := _get_cell_column(cell)
	if column_index != _get_cell_column(edited_cells[edited_cells.size() - 1]):
		return
	
	var row_start = _get_cell_row(edited_cells[edited_cells.size() - 1]) - first_row
	var row_end := _get_cell_row(cell) - first_row
	var edge_shift = -1 if row_start > row_end else 1
	row_start += edge_shift
	row_end += edge_shift
	var table_root := get_node(path_table_root)

	for i in range(row_start, row_end, edge_shift):
		var cur_cell := table_root.get_child(i * columns.size() + column_index)
		if !cur_cell.visible:
			# When search is active, some cells will be hidden.
			continue

		column_editors[column_index].set_selected(cur_cell, true)
		if !cur_cell in edited_cells:
			edited_cells.append(cur_cell)
			if column_editors[column_index].is_text():
				edited_cells_text.append(str(cur_cell.text))
				edit_cursor_positions.append(cur_cell.text.length())

	emit_signal("cells_selected", edited_cells)


func select_column(column_index : int):
	deselect_all_cells()
	select_cell(get_node(path_table_root).get_child(column_index))
	select_cells_to(get_node(path_table_root).get_child(column_index + columns.size() * (last_row - first_row - 1)))


func hide_column(column_index : int):
	hidden_columns[current_path][columns[column_index]] = true
	save_data()
	_update_hidden_columns()
	_update_column_sizes()


func get_selected_column() -> int:
	return _get_cell_column(edited_cells[0])


func _add_cell_to_selection(cell : Control):
	column_editors[_get_cell_column(cell)].set_selected(cell, true)
	edited_cells.append(cell)
	if column_editors[_get_cell_column(cell)].is_text():
		edited_cells_text.append(str(cell.text))
		edit_cursor_positions.append(cell.text.length())


func _try_open_docks(cell : Control):
	var column_index = _get_cell_column(cell)
	for x in get_node(path_property_editors).get_children():
		x.visible = x.try_edit_value(
			io.get_value(rows[_get_cell_row(cell)], columns[column_index]),
			column_types[column_index],
			column_hints[column_index]
		)
		x.get_node(x.path_property_name).text = columns[column_index]


func set_edited_cells_values(new_cell_values : Array):
	var column = _get_cell_column(edited_cells[0])
	var edited_cells_resources = _get_edited_cells_resources()

	# Duplicated here since if using text editing, edited_cells_text needs to modified
	# but here, it would be converted from a String breaking editing
	new_cell_values = new_cell_values.duplicate()

	editor_plugin.undo_redo.create_action("Set Cell Values")
	editor_plugin.undo_redo.add_undo_method(
		self,
		"_update_resources",
		edited_cells_resources.duplicate(),
		edited_cells.duplicate(),
		column,
		get_edited_cells_values()
	)
	editor_plugin.undo_redo.add_undo_method(
		self,
		"_update_selected_cells_text"
	)
	editor_plugin.undo_redo.add_do_method(
		self,
		"_update_resources",
		edited_cells_resources.duplicate(),
		edited_cells.duplicate(),
		column,
		new_cell_values.duplicate()
	)
	editor_plugin.undo_redo.commit_action()
	editor_interface.get_resource_filesystem().scan()
	undo_redo_version = editor_plugin.undo_redo.get_version()
	_update_column_sizes()


func rename_row(row, new_name):
	if !has_row_names(): return
		
	io.rename_row(row, new_name)
	refresh()


func duplicate_selected_rows(new_name : String):
	io.duplicate_rows(_get_edited_cells_resources(), new_name)
	refresh()


func delete_selected_rows():
	io.delete_rows(_get_edited_cells_resources())
	refresh()


func has_row_names():
	return io.has_row_names()


func get_last_selected_row():
	return rows[_get_cell_row(edited_cells[-1])]


func _update_selected_cells_text():
	if edited_cells_text.size() == 0:
		return
		
	for i in edited_cells.size():
		edited_cells_text[i] = str(edited_cells[i].text)
		edit_cursor_positions[i] = edited_cells_text[i].length()


func get_edited_cells_values() -> Array:
	var arr := edited_cells.duplicate()
	var column_index := _get_cell_column(edited_cells[0])
	var cell_editor = column_editors[column_index]
	for i in arr.size():
		arr[i] = io.get_value(rows[_get_cell_row(arr[i])], columns[column_index])
	
	return arr


func get_cell_value(cell : Control):
	return io.get_value(rows[_get_cell_row(cell)], columns[_get_cell_column(cell)])


func _can_select_cell(cell : Control) -> bool:
	if edited_cells.size() == 0:
		return true
	
	if !Input.is_key_pressed(KEY_CONTROL):
		return false
	
	if (
		_get_cell_column(cell)
		!= _get_cell_column(edited_cells[0])
	):
		return false
	
	return !cell in edited_cells


func _get_cell_column(cell) -> int:
	return cell.get_position_in_parent() % columns.size()


func _get_cell_row(cell) -> int:
	return cell.get_position_in_parent() / columns.size() + first_row


func _update_scroll():
	get_node(path_columns).rect_position.x = -get_node(path_table_root).get_node("../..").scroll_horizontal
	

func _on_cell_gui_input(event : InputEvent, cell : Control):
	if event is InputEventMouseButton:
		_update_scroll()
		if event.button_index != BUTTON_LEFT:
			if event.button_index == BUTTON_RIGHT && event.is_pressed():
				if !cell in edited_cells:
					deselect_all_cells()
					select_cell(cell)

				emit_signal("cells_context", edited_cells)

			return

		grab_focus()
		if event.pressed:
			if Input.is_key_pressed(KEY_CONTROL):
				if cell in edited_cells:
					deselect_cell(cell)

				else:
					select_cell(cell)

			elif Input.is_key_pressed(KEY_SHIFT):
				select_cells_to(cell)

			else:
				deselect_all_cells()
				select_cell(cell)


func _gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		_update_scroll()
		if event.button_index != BUTTON_LEFT:
			if event.button_index == BUTTON_RIGHT && event.is_pressed():
				emit_signal("cells_context", edited_cells)

			return

		grab_focus()
		if !event.pressed:
			deselect_all_cells()


func _input(event : InputEvent):
	if !event is InputEventKey or !event.pressed:
		return
	
	if !has_focus() or edited_cells.size() == 0:
		return

	if event.scancode == KEY_CONTROL or event.scancode == KEY_SHIFT:
		# Modifier keys do not get processed.
		return
	
	# Ctrl + Z (before, and instead of, committing the action!)
	if Input.is_key_pressed(KEY_CONTROL):
		if event.scancode == KEY_Z:
			if Input.is_key_pressed(KEY_SHIFT):
				editor_plugin.undo_redo.redo()
			# Ctrl + z
			else:
				editor_plugin.undo_redo.undo()
			
			return

		# This shortcut is used by Godot as well.
		if event.scancode == KEY_Y:
			editor_plugin.undo_redo.redo()
			return
				
	_key_specific_action(event)
	grab_focus()
	
	editor_interface.get_resource_filesystem().scan()
	undo_redo_version = editor_plugin.undo_redo.get_version()


func _key_specific_action(event : InputEvent):
	var column = _get_cell_column(edited_cells[0])
	var ctrl_pressed := Input.is_key_pressed(KEY_CONTROL)
	if ctrl_pressed:
		editor_plugin.hide_bottom_panel()

	# CURSOR MOVEMENT
	if event.scancode == KEY_LEFT:
		TextEditingUtils.multi_move_left(
			edited_cells_text, edit_cursor_positions, Input.is_key_pressed(KEY_CONTROL)
		)
	
	elif event.scancode == KEY_RIGHT:
		TextEditingUtils.multi_move_right(
			edited_cells_text, edit_cursor_positions, Input.is_key_pressed(KEY_CONTROL)
		)
	
	elif event.scancode == KEY_HOME:
		for i in edit_cursor_positions.size():
			edit_cursor_positions[i] = 0

	elif event.scancode == KEY_END:
		for i in edit_cursor_positions.size():
			edit_cursor_positions[i] = edited_cells_text[i].length()
	
	# BETWEEN-CELL NAVIGATION
	elif event.scancode == KEY_UP:
		_move_selection_on_grid(0, (-1 if !ctrl_pressed else -10))

	elif event.scancode == KEY_DOWN:
		_move_selection_on_grid(0, (1 if !ctrl_pressed else 10))

	elif Input.is_key_pressed(KEY_SHIFT) and event.scancode == KEY_TAB:
		_move_selection_on_grid((-1 if !ctrl_pressed else -10), 0)
		get_tree().set_input_as_handled()
	
	elif event.scancode == KEY_TAB:
		_move_selection_on_grid((1 if !ctrl_pressed else 10), 0)
		get_tree().set_input_as_handled()

	# Ctrl + C (so you can edit in a proper text editor instead of this wacky nonsense)
	elif ctrl_pressed and event.scancode == KEY_C:
		TextEditingUtils.multi_copy(edited_cells_text)
		get_tree().set_input_as_handled()
			
	# The following actions do not work on non-editable cells.
	if !column_editors[column].is_text() or columns[column] == "resource_path":
		return
	
	# Ctrl + V
	elif ctrl_pressed and event.scancode == KEY_V:
		set_edited_cells_values(TextEditingUtils.multi_paste(
			edited_cells_text, edit_cursor_positions
		))
		get_tree().set_input_as_handled()

	# ERASING
	elif event.scancode == KEY_BACKSPACE:
		set_edited_cells_values(TextEditingUtils.multi_erase_left(
			edited_cells_text, edit_cursor_positions, Input.is_key_pressed(KEY_CONTROL)
		))

	elif event.scancode == KEY_DELETE:
		set_edited_cells_values(TextEditingUtils.multi_erase_right(
			edited_cells_text, edit_cursor_positions, Input.is_key_pressed(KEY_CONTROL)
		))
		get_tree().set_input_as_handled() # Because this is one dangerous action.

	# And finally, text typing.
	elif event.scancode == KEY_ENTER:
		set_edited_cells_values(TextEditingUtils.multi_input(
			"\n", edited_cells_text, edit_cursor_positions
		))

	elif event.unicode != 0 and event.unicode != 127:
		set_edited_cells_values(TextEditingUtils.multi_input(
			char(event.unicode), edited_cells_text, edit_cursor_positions
		))


func _move_selection_on_grid(move_h : int, move_v : int):
	select_cell(
		get_node(path_table_root).get_child(
			edited_cells[0].get_position_in_parent()
			+ move_h + move_v * columns.size()
		)
	)
	deselect_cell(edited_cells[0])


func _update_resources(update_rows : Array, update_cells : Array, update_column : int, values : Array):
	var saved_indices = []
	saved_indices.resize(update_rows.size())
	for i in update_rows.size():
		var row = _get_cell_row(update_cells[i])
		saved_indices[i] = row
		column_editors[update_column].set_value(update_cells[i], values[i])
		values[i] = _try_convert(values[i], column_types[update_column])
		if values[i] == null:
			continue
		
		io.set_value(
			update_rows[i],
			columns[update_column],
			values[i],
			row
		)
		if column_types[update_column] == TYPE_COLOR:
			for j in columns.size() - update_column:
				if j != 0 and column_types[j + update_column] == TYPE_COLOR:
					break
				
				column_editors[j + update_column].set_color(
					update_cells[i].get_parent().get_child(
						_get_cell_row(update_cells[i]) * columns.size() + update_column + j - first_row
					),
					values[i]
				)

	io.save_entries(rows, saved_indices)
	_update_column_sizes()


func _try_convert(value, type):
	if type == TYPE_BOOL:
		_update_selected_cells_text()
		# "off" displayed in lowercase, "ON" in uppercase.
		return value[0] == "o"

	# If it can't convert, throws exception and returns null.
	return convert(value, type)


func _get_edited_cells_resources() -> Array:
	var arr := []
	arr.resize(edited_cells.size())
	for i in arr.size():
		arr[i] = rows[_get_cell_row(edited_cells[i])]

	return arr


func _on_SearchCond_text_entered(new_text : String):
	var new_script := GDScript.new()
	new_script.source_code = "static func can_show(res, index):\n\treturn " + new_text
	new_script.reload()

	var new_script_instance = new_script.new()
	search_cond = new_script_instance
	refresh()


func _on_ProcessExpr_text_entered(new_text : String):
	if new_text == "":
		new_text = "true"

	var new_script := GDScript.new()
	new_script.source_code = "static func get_result(value, res, row_index, cell_index):\n\treturn " + new_text
	new_script.reload()

	var new_script_instance = new_script.new()
	var values = get_edited_cells_values()
	var cur_row := 0
	
	for i in values.size():
		cur_row = _get_cell_row(edited_cells[i])
		values[i] = new_script_instance.get_result(values[i], rows[cur_row], cur_row, i)

	set_edited_cells_values(values)


func _on_inspector_property_edited(property : String):
	if !visible: return
	if inspector_resource == null: return
	if undo_redo_version > editor_plugin.undo_redo.get_version(): return

	var value = inspector_resource.get(property)
	var values = []
	values.resize(edited_cells.size())
	for i in edited_cells.size():
		values[i] = value
	
	var previously_edited = edited_cells
	if columns[_get_cell_column(edited_cells[0])] != property:
		previously_edited = previously_edited.duplicate()
		var new_column := columns.find(property)
		deselect_all_cells()
		var index := 0
		for i in previously_edited.size():
			index = _get_cell_row(previously_edited[i]) * columns.size() + new_column
			_add_cell_to_selection(get_node(path_table_root).get_child(index - first_row))

	set_edited_cells_values(values)
	_try_open_docks(edited_cells[0])


func _on_VisibleCols_about_to_show():
	var popup = get_node(path_hide_columns_button).get_popup()
	popup.clear()
	popup.hide_on_checkable_item_selection = false
	
	for i in columns.size():
		popup.add_check_item(TextEditingUtils.string_snake_to_naming_case(columns[i]), i)
		popup.set_item_checked(i, hidden_columns[current_path].has(columns[i]))


func _on_VisibleCols_id_pressed(id : int):
	var popup = get_node(path_hide_columns_button).get_popup()
	if popup.is_item_checked(id):
		popup.set_item_checked(id, false)
		hidden_columns[current_path].erase(columns[id])

	else:
		popup.set_item_checked(id, true)
		hidden_columns[current_path][columns[id]] = true

	save_data()
	_update_hidden_columns()
	_update_column_sizes()
