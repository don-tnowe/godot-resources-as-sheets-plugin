tool
extends Control

export var table_header_scene : PackedScene

export(Array, Script) var cell_editor_classes := []

export var path_folder_path := NodePath("")
export var path_recent_paths := NodePath("")
export var path_table_root := NodePath("")
export var path_property_editors := NodePath("")
export var path_columns := NodePath("")

var editor_interface : EditorInterface
var editor_plugin : EditorPlugin

var current_path := ""
var recent_paths := []
var save_data_path : String = get_script().resource_path.get_base_dir() + "/saved_state.json"
var sorting_by := ""
var sorting_reverse := false
var is_undo_redoing := false
var undo_redo_version := 0

var all_cell_editors := []

var columns := []
var column_types := []
var column_hints := []
var column_editors := []
var rows := []
var remembered_paths := {}

var edited_cells := []
var edited_cells_text := []
var edit_cursor_positions := []
var inspector_resource : Resource
var search_cond : Reference


func _ready():
	get_node(path_recent_paths).clear()
	editor_plugin.get_undo_redo().connect("version_changed", self, "_on_undo_redo_version_changed")
	editor_interface.get_resource_filesystem()\
		.connect("filesystem_changed", self, "_on_filesystem_changed")
	editor_interface.get_inspector()\
		.connect("property_edited", self, "_on_inspector_property_edited")

	# Load saved recent paths
	var file := File.new()
	if file.file_exists(save_data_path):
		file.open(save_data_path, File.READ)

		var as_text = file.get_as_text()
		var as_var = str2var(as_text)
		for x in as_var["recent_paths"]:
			add_path_to_recent(x, true)

	# Load cell editors and instantiate them
	for x in cell_editor_classes:
		all_cell_editors.append(x.new())
		all_cell_editors[all_cell_editors.size() - 1].hint_strings_array = column_hints

	display_folder(recent_paths[0], "resource_name", false, true)


func _on_undo_redo_version_changed():
	is_undo_redoing = true


func _on_filesystem_changed():
	var path = editor_interface.get_resource_filesystem().get_filesystem_path(current_path)
	if !path: return
	if path.get_file_count() != rows.size():
		display_folder(current_path, sorting_by, sorting_reverse, true)

	else:
		for k in remembered_paths:
			if remembered_paths[k].resource_path != k:
				var res = remembered_paths[k]
				remembered_paths.erase(k)
				remembered_paths[res.resource_path] = res
				display_folder(current_path, sorting_by, sorting_reverse, true)
				break


func display_folder(folderpath : String, sort_by : String = "", sort_reverse : bool = false, force_rebuild : bool = false):
	if folderpath == "": return  # Root folder resources tend to have MANY properties.
	$"HeaderContentSplit/MarginContainer/FooterContentSplit/Panel/Label".visible = false
	if !folderpath.ends_with("/"):
		folderpath += "/"
	
	_load_resources_from_folder(folderpath, sort_by, sort_reverse)
	if columns.size() == 0: return

	get_node(path_folder_path).text = folderpath
	_create_table(force_rebuild or current_path != folderpath)
	_apply_search_cond()
	current_path = folderpath
	yield(get_tree(), "idle_frame")
	if get_node(path_table_root).get_child_count() == 0:
		display_folder(folderpath, sort_by, sort_reverse, force_rebuild)


func _load_resources_from_folder(folderpath : String, sort_by : String, sort_reverse : bool):
	var dir := Directory.new()
	dir.open(folderpath)
	dir.list_dir_begin()

	rows.clear()
	remembered_paths.clear()
	var cur_dir_script : Script = null

	var filepath = dir.get_next()
	var res : Resource

	while filepath != "":
		if filepath.ends_with(".tres"):
			filepath = folderpath + filepath
			res = load(filepath)
			if !is_instance_valid(cur_dir_script):
				columns.clear()
				column_types.clear()
				column_hints.clear()
				column_editors.clear()
				for x in res.get_property_list():
					if x["usage"] & PROPERTY_USAGE_EDITOR != 0 and x["name"] != "script":
						columns.append(x["name"])
						column_types.append(x["type"])
						column_hints.append(x["hint_string"].split(","))
						for y in all_cell_editors:
							if y.can_edit_value(res.get(x["name"]), x["type"], x["hint"]):
								column_editors.append(y)
								break
								
				cur_dir_script = res.get_script()
				if !(sort_by in res):
					sort_by = "resource_path"

			if res.get_script() == cur_dir_script:
				_insert_row_sorted(res, rows, sort_by, sort_reverse)
				remembered_paths[res.resource_path] = res
		
		filepath = dir.get_next()


func _insert_row_sorted(res : Resource, rows : Array, sort_by : String, sort_reverse : bool):
	for i in rows.size():
		if sort_reverse == _compare_values(res.get(sort_by), rows[i].get(sort_by)):
			rows.insert(i, res)
			return

	rows.append(res)


func _compare_values(a, b) -> bool:
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
			x.queue_free()
		
		for x in headers_node.get_children():
			x.queue_free()

		for x in columns:
			new_node = table_header_scene.instance()
			headers_node.add_child(new_node)
			new_node.get_node("Button").text = x
			new_node.get_node("Button").hint_tooltip = x
			new_node.get_node("Button").connect("pressed", self, "_set_sorting", [x])
	
	var to_free = root_node.get_child_count() - rows.size() * columns.size()
	while to_free > 0:
		root_node.get_child(columns.size()).free()
		to_free -= 1
	
	for i in rows.size():
		_update_row(i, ProjectSettings.get_setting(SettingsGrid.SETTING_PREFIX + "color_rows"))

	_update_column_sizes()


func _update_column_sizes():
	yield(get_tree(), "idle_frame")
	var column_headers := get_node(path_columns).get_children()
	var table_root := get_node(path_table_root)
	var clip_text : bool = ProjectSettings.get_setting(SettingsGrid.SETTING_PREFIX + "clip_headers")
	var min_width := 0
	var cell : Control

	get_node(path_columns).get_parent().rect_min_size.y = get_node(path_columns).rect_size.y
	for i in column_headers.size():
		cell = table_root.get_child(i)

		column_headers[i].get_child(0).clip_text = clip_text
		column_headers[i].rect_min_size.x = 0
		cell.rect_min_size.x = 0
		column_headers[i].rect_size.x = 0
		get_node(path_columns).queue_sort()

		min_width = max(column_headers[i].rect_size.x, cell.rect_size.x)
		column_headers[i].rect_min_size.x = min_width
		cell.rect_min_size.x = column_headers[i].get_minimum_size().x
		column_headers[i].rect_size.x = min_width

	get_node(path_columns).queue_sort()
		

func _update_row(row_index : int, color_rows : bool = true):
	var root_node = get_node(path_table_root)
	var current_node : Control
	var next_color := Color.white
	for i in columns.size():
		if root_node.get_child_count() <= row_index * columns.size() + i:
			current_node = column_editors[i].create_cell(self)
			current_node.connect("gui_input", self, "_on_cell_gui_input", [current_node])
			root_node.add_child(current_node)

		else:
			current_node = root_node.get_child(row_index * columns.size() + i)
			current_node.hint_tooltip = columns[i] + "\nOf " + rows[row_index].resource_path.get_file().get_basename()

		column_editors[i].set_value(current_node, rows[row_index].get(columns[i]))
		if columns[i] == "resource_path":
			column_editors[i].set_value(current_node, current_node.text.get_file().get_basename())

		if color_rows and column_types[i] == TYPE_COLOR:
			next_color = rows[row_index].get(columns[i])

		column_editors[i].set_color(current_node, next_color)


func _apply_search_cond():
	if search_cond == null:
		_on_SearchCond_text_entered("true")

	var table_elements = get_node(path_table_root).get_children()
	
	for i in rows.size():
		var row_visible = search_cond.can_show(rows[i], i)
		for j in columns.size():
			table_elements[i * columns.size() + j].visible = row_visible


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
		}
	))


func _on_Path_text_entered(new_text : String = ""):
	if new_text != "":
		current_path = new_text
		add_path_to_recent(new_text)
		display_folder(new_text, "", false, true)

	else:
		display_folder(current_path, sorting_by, sorting_reverse, true)


func _on_RecentPaths_item_selected(index : int):
	current_path = recent_paths[index]
	get_node(path_folder_path).text = recent_paths[index]
	display_folder(current_path)


func _on_FileDialog_dir_selected(dir : String):
	get_node(path_folder_path).text = dir
	add_path_to_recent(dir)
	display_folder(dir)


func deselect_all_cells():
	for x in edited_cells:
		column_editors[_get_cell_column(x)].set_selected(x, false)

	edited_cells.clear()
	edited_cells_text.clear()
	edit_cursor_positions.clear()


func deselect_cell(cell : Control):
	var idx := edited_cells.find(cell)
	if idx == -1: return

	column_editors[_get_cell_column(cell)].set_selected(cell, false)
	edited_cells.remove(idx)
	if edited_cells_text.size() != 0:
		edited_cells_text.remove(idx)
		edit_cursor_positions.remove(idx)


func select_cell(cell : Control):
	var column_index := _get_cell_column(cell)
	if _can_select_cell(cell):
		_add_cell_to_selection(cell)
		_try_open_docks(cell)
		inspector_resource = rows[_get_cell_row(cell)].duplicate()
		editor_plugin.get_editor_interface().edit_resource(inspector_resource)


func select_cells_to(cell : Control):
	var column_index := _get_cell_column(cell)
	if column_index != _get_cell_column(edited_cells[edited_cells.size() - 1]):
		return
	
	var row_start = _get_cell_row(edited_cells[edited_cells.size() - 1])
	var row_end := _get_cell_row(cell)
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
			rows[_get_cell_row(cell)].get(columns[column_index]),
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
		arr[i] = rows[_get_cell_row(arr[i])].get(columns[column_index])
	
	return arr


func get_cell_value(cell : Control):
	return rows[_get_cell_row(cell)].get(columns[_get_cell_column(cell)])


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
	return cell.get_position_in_parent() / columns.size()


func _update_scroll():
	get_node(path_columns).rect_position.x = -get_node(path_table_root).get_node("../..").scroll_horizontal
	

func _on_cell_gui_input(event : InputEvent, cell : Control):
	if event is InputEventMouseButton:
		_update_scroll()
		if event.button_index != BUTTON_LEFT:
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
			return

		grab_focus()
		if !event.pressed:
			deselect_all_cells()


func _input(event : InputEvent):
	if !event is InputEventKey or !event.pressed:
		return
	
	if !has_focus() or edited_cells.size() == 0:
		return

	var column = _get_cell_column(edited_cells[0])
	if column_types[column] == TYPE_OBJECT || columns[column] == "resource_path":
		return
	
	if event.scancode == KEY_CONTROL or event.scancode == KEY_SHIFT:
		# Modifier keys do not get processed.
		return
	
	# Ctrl + Z (before, and instead of, committing the action!)
	if Input.is_key_pressed(KEY_CONTROL) and event.scancode == KEY_Z:
		if Input.is_key_pressed(KEY_SHIFT):
			editor_plugin.undo_redo.redo()
		# Ctrl + z
		else:
			editor_plugin.undo_redo.undo()
		
		return

	# This shortcut is used by Godot as well.	
	if Input.is_key_pressed(KEY_CONTROL) and event.scancode == KEY_Y:
		editor_plugin.undo_redo.redo()
		return
	
	if !column_editors[column].is_text():
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

	# Ctrl + V
	elif ctrl_pressed and event.scancode == KEY_V:
		set_edited_cells_values(TextEditingUtils.multi_paste(
			edited_cells_text, edit_cursor_positions
		))

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


func set_cell(cell, value):
	var column = _get_cell_column(cell)
	if columns[column] == "resource_path":
		return
		
	column_editors[column].set_value(cell, value)


func _update_resources(update_rows : Array, update_cells : Array, update_column : int, values : Array):
	for i in update_rows.size():
		column_editors[update_column].set_value(update_cells[i], values[i])
		values[i] = _try_convert(values[i], column_types[update_column])
		if values[i] == null:
			continue

		update_rows[i].set(columns[update_column], convert(values[i], column_types[update_column]))
		ResourceSaver.save(update_rows[i].resource_path, update_rows[i])
		if column_types[update_column] == TYPE_COLOR:
			for j in columns.size() - update_column:
				if j != 0 and column_types[j + update_column] == TYPE_COLOR:
					break
				
				column_editors[j + update_column].set_color(
					update_cells[i].get_parent().get_child(
						_get_cell_row(update_cells[i]) * columns.size() + update_column + j
					),
					values[i]
				)

	_update_column_sizes()


func _try_convert(value, type):
	if type == TYPE_BOOL:
		_update_selected_cells_text()
		# "off" displayed in lowercase, "ON" in uppercase.
		return value[0] == "o"

	# If it can't convert, throws exception and returns null.
	return convert(value, type)


func _get_edited_cells_resources() -> Array:
	var arr := edited_cells.duplicate()
	for i in arr.size():
		arr[i] = rows[_get_cell_row(edited_cells[i])]

	return arr


func _on_SearchCond_text_entered(new_text : String):
	var new_script := GDScript.new()
	new_script.source_code = "static func can_show(res, index):\n\treturn " + new_text
	new_script.reload()

	var new_script_instance = new_script.new()
	search_cond = new_script_instance
	_apply_search_cond()


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
			_add_cell_to_selection(get_node(path_table_root).get_child(index))

	set_edited_cells_values(values)
	_try_open_docks(edited_cells[0])
