tool
extends Control

export var table_header_scene : PackedScene

export(Array, Script) var cell_editor_classes := []

export var path_folder_path := NodePath("")
export var path_recent_paths := NodePath("")
export var path_table_root := NodePath("")
export var path_property_editors := NodePath("")

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
var edit_cursor_positions := []


func _ready():
	get_node(path_recent_paths).clear()
	editor_plugin.get_undo_redo().connect("version_changed", self, "_on_undo_redo_version_changed")
	editor_interface.get_resource_filesystem()\
		.connect("filesystem_changed", self, "_on_filesystem_changed")

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

	display_folder(recent_paths[0])


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
				display_folder(current_path, sorting_by, sorting_reverse, true)
				break


func display_folder(folderpath : String, sort_by : String = "", sort_reverse : bool = false, force_rebuild : bool = false):
	if folderpath == "": return  # Root folder resources tend to have MANY properties.
	if !folderpath.ends_with("/"):
		folderpath += "/"
	
	_load_resources_from_folder(folderpath, sort_by, sort_reverse)
	if columns.size() == 0: return

	get_node(path_folder_path).text = folderpath
	_create_table(get_node(path_table_root), force_rebuild or current_path != folderpath)
	current_path = folderpath


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
						column_hints.append(x["hint"])
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
		if sort_reverse != (res.get(sort_by) < rows[i].get(sort_by)):
			rows.insert(i, res)
			return

	rows.append(res)


func _set_sorting(sort_by):
	var sort_reverse : bool = !(sorting_by != sort_by or sorting_reverse)
	sorting_reverse = sort_reverse
	display_folder(current_path, sort_by, sort_reverse)
	sorting_by = sort_by


func _create_table(root_node : Control, columns_changed : bool):
	edited_cells = []
	edit_cursor_positions = []
	var new_node : Control
	if columns_changed:
		root_node.columns = columns.size()
		for x in root_node.get_children():
			x.queue_free()
		
		for x in columns:
			new_node = table_header_scene.instance()
			root_node.add_child(new_node)
			new_node.get_node("Button").text = x
			new_node.get_node("Button").connect("pressed", self, "_set_sorting", [x])

	var to_free = root_node.get_child_count() - (rows.size() + 1) * columns.size()
	while to_free > 0:
		root_node.get_child(columns.size()).free()
		to_free -= 1
	
	var next_color := Color.white
	for i in rows.size():
		for j in columns.size():
			if root_node.get_child_count() <= (i + 1) * columns.size() + j:
				new_node = column_editors[j].create_cell()
				new_node.connect("gui_input", self, "_on_cell_gui_input", [new_node])
				root_node.add_child(new_node)

			else:
				new_node = root_node.get_child((i + 1) * columns.size() + j)
				new_node.hint_tooltip = columns[j] + "\nOf " + rows[i].resource_path.get_file()

			column_editors[j].set_value(new_node, rows[i].get(columns[j]))
			if columns[j] == "resource_path":
				column_editors[j].set_value(new_node, new_node.text.get_file())

			if j == 0:
				next_color = Color.white
			
			if column_types[j] == TYPE_COLOR:
				next_color = rows[i].get(columns[j])

			column_editors[j].set_color(new_node, next_color)


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


func _on_Path_text_entered(new_text : String):
	current_path = new_text

	add_path_to_recent(new_text)
	display_folder(new_text, "", false, true)


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
	edit_cursor_positions.clear()


func deselect_cell(cell : Control):
	var idx := edited_cells.find(cell)
	if idx == -1: return

	column_editors[_get_cell_column(cell)].set_selected(cell, false)
	edited_cells.remove(idx)
	edit_cursor_positions.remove(idx)


func select_cell(cell : Control):
	var column_index := _get_cell_column(cell)
	if _can_select_cell(cell):
		column_editors[column_index].set_selected(cell, true)
		edited_cells.append(cell)
		edit_cursor_positions.append(column_editors[column_index].get_text_length(cell))

		for x in get_node(path_property_editors).get_children():
			x.visible = x.can_edit_value(
				column_editors[column_index].get_value(cell),
				column_types[_get_cell_column(cell)],
				column_hints[_get_cell_column(cell)]
			)
		return

	if column_index != _get_cell_column(edited_cells[edited_cells.size() - 1]):
		return
	
	var row_start = _get_cell_row(edited_cells[edited_cells.size() - 1])
	var row_end := _get_cell_row(cell)
	var table_root := get_node(path_table_root)

	for i in range(row_end, row_start, 1 if row_start > row_end else -1):
		var cur_cell := table_root.get_child(i * columns.size() + column_index)
		if !cur_cell.visible:
			# When search is active, some cells will be hidden.
			continue

		column_editors[column_index].set_selected(cur_cell, true)
		edited_cells.append(cur_cell)
		edit_cursor_positions.append(column_editors[column_index].get_text_length(cur_cell))


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


func _on_cell_gui_input(event : InputEvent, cell : Control):
	if event is InputEventMouseButton:
		if event.button_index != BUTTON_LEFT:
			return

		grab_focus()
		if event.pressed:
			if cell in edited_cells:
				if !Input.is_key_pressed(KEY_CONTROL):
					deselect_cell(cell)

				else:
					deselect_all_cells()
					select_cell(cell)

			else:
				if !(Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_CONTROL)):
					deselect_all_cells()

				select_cell(cell)

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			select_cell(cell)


func _gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		grab_focus()
		if !event.pressed:
			deselect_all_cells()


func _input(event : InputEvent):
	if !event is InputEventKey or !event.pressed:
		return
	
	if !visible or edited_cells.size() == 0:
		return
	
	if column_types[_get_cell_column(edited_cells[0])] == TYPE_OBJECT:
		return
	
	if event.scancode == KEY_CONTROL or event.scancode == KEY_SHIFT:
		# Modifier keys do not get processed.
		return
	
	var edited_cells_resources = _get_edited_cells_resources()

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

	editor_plugin.undo_redo.create_action("Set Cell Value")
	editor_plugin.undo_redo.add_undo_method(
		self,
		"_update_resources",
		edited_cells_resources.duplicate(),
		edited_cells.duplicate(),
		_get_cell_column(edited_cells[0]),
		_get_edited_cells_values()
	)

	_key_specific_action(event)
	grab_focus()
	
	editor_plugin.undo_redo.add_do_method(
		self,
		"_update_resources",
		edited_cells_resources.duplicate(),
		edited_cells.duplicate(),
		_get_cell_column(edited_cells[0]),
		_get_edited_cells_values()
	)
	editor_plugin.undo_redo.commit_action()
	editor_interface.get_resource_filesystem().scan()
	undo_redo_version = editor_plugin.undo_redo.get_version()


func _key_specific_action(event : InputEvent):
	var column = _get_cell_column(edited_cells[0])
	var ctrl_pressed := Input.is_key_pressed(KEY_CONTROL)
	if ctrl_pressed:
		editor_plugin.hide_bottom_panel()

	# ERASING
	if event.scancode == KEY_BACKSPACE:
		TextEditingUtils.multi_erase_left(edited_cells, edit_cursor_positions, column_editors[column], self)

	if event.scancode == KEY_DELETE:
		TextEditingUtils.multi_erase_right(edited_cells, edit_cursor_positions, column_editors[column], self)
		get_tree().set_input_as_handled() # Because this is one dangerous action.

	# CURSOR MOVEMENT
	elif event.scancode == KEY_LEFT:
		TextEditingUtils.multi_move_left(edited_cells, edit_cursor_positions, column_editors[column])
	
	elif event.scancode == KEY_RIGHT:
		TextEditingUtils.multi_move_right(edited_cells, edit_cursor_positions, column_editors[column])
	
	elif event.scancode == KEY_HOME:
		for i in edit_cursor_positions.size():
			edit_cursor_positions[i] = 0

	elif event.scancode == KEY_END:
		for i in edit_cursor_positions.size():
			edit_cursor_positions[i] = column_editors[column].get_text_length(edited_cells[i])
	
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
		TextEditingUtils.multi_copy(edited_cells)

	# Ctrl + V
	elif ctrl_pressed and event.scancode == KEY_V:
		TextEditingUtils.multi_paste(edited_cells, edit_cursor_positions, column_editors[column], self)

	# Line Skip
	elif event.scancode == KEY_ENTER:
		TextEditingUtils.multi_linefeed(edited_cells, edit_cursor_positions, column_editors[column], self)
	
	# And finally, text typing.
	elif event.unicode != 0 and event.unicode != 127:
		TextEditingUtils.multi_input(char(event.unicode), edited_cells, edit_cursor_positions, column_editors[column], self)


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
	var cells := get_node(path_table_root).get_children()
	for i in update_rows.size():
		update_rows[i].set(columns[update_column], values[i])
		ResourceSaver.save(update_rows[i].resource_path, update_rows[i])
		if undo_redo_version > editor_plugin.undo_redo.get_version():
			column_editors[update_column].set_value(update_cells[i], values[i])


func _get_edited_cells_resources() -> Array:
	var arr := edited_cells.duplicate()
	for i in arr.size():
		arr[i] = rows[_get_cell_row(edited_cells[i]) - 1]

	return arr


func _get_edited_cells_values() -> Array:
	var arr := edited_cells.duplicate()
	var cell_editor = column_editors[_get_cell_column(edited_cells[0])]
	for i in arr.size():
		arr[i] = cell_editor.get_value(edited_cells[i])

	return arr


func _on_SearchCond_text_entered(new_text : String):
	var new_script := GDScript.new()
	new_script.source_code = "static func can_show(res, index):\n\treturn " + new_text
	new_script.reload()

	var new_script_instance = new_script.new()
	var table_elements = get_node(path_table_root).get_children()
	
	for i in rows.size():
		var row_visible = new_script_instance.can_show(rows[i], i)
		for j in columns.size():
			table_elements[(i + 1) * columns.size() + j].visible = row_visible


func _on_focus_exited():
	deselect_all_cells()
