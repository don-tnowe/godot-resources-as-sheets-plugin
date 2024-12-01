@tool
extends Node

const TablesPluginEditorViewClass := preload("res://addons/resources_spreadsheet_view/editor_view.gd")
const TablesPluginSelectionManagerClass := preload("res://addons/resources_spreadsheet_view/main_screen/selection_manager.gd")
const TextEditingUtilsClass := preload("res://addons/resources_spreadsheet_view/text_editing_utils.gd")

@onready var editor_view : TablesPluginEditorViewClass = get_parent()
@onready var selection : TablesPluginSelectionManagerClass = get_node("../SelectionManager")


func _on_cell_gui_input(event : InputEvent, cell_node : Control):
	var cell := selection.get_cell_node_position(cell_node)
	if event is InputEventMouseButton:
		editor_view.grab_focus()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if !cell in selection.edited_cells:
				selection.deselect_all_cells()
				selection.select_cell(cell)

			selection.rightclick_cells()

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Input.is_key_pressed(KEY_CTRL):
				if cell in selection.edited_cells:
					selection.deselect_cell(cell)

				else:
					selection.select_cell(cell)

			elif Input.is_key_pressed(KEY_SHIFT):
				selection.select_cells_to(cell)

			else:
				selection.deselect_all_cells()
				selection.select_cell(cell)


func _gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			selection.rightclick_cells()

		if event.button_index == MOUSE_BUTTON_LEFT:
			editor_view.grab_focus()
			if !event.pressed:
				selection.deselect_all_cells()


func _input(event : InputEvent):
	if !event is InputEventKey or !event.pressed:
		return
	
	if !editor_view.has_focus() or selection.edited_cells.size() == 0:
		return

	if event.keycode == KEY_CTRL or event.keycode == KEY_SHIFT:
		# Modifier keys do not get processed.
		return
	
	# Ctrl + Z (before, and instead of, committing the action!)
	if Input.is_key_pressed(KEY_CTRL):
		if event.keycode == KEY_Z or event.keycode == KEY_Y:
			return

	_key_specific_action(event)
	editor_view.grab_focus()
	editor_view.editor_interface.get_resource_filesystem().scan()


func _key_specific_action(event : InputEvent):
	var column := selection.get_cell_column(selection.edited_cells[0])
	var ctrl_pressed := Input.is_key_pressed(KEY_CTRL)

	# BETWEEN-CELL NAVIGATION
	var grid_move_offset := (10 if ctrl_pressed else 1)
	if event.keycode == KEY_UP:
		_move_selection_on_grid(0, -grid_move_offset)

	elif event.keycode == KEY_DOWN:
		_move_selection_on_grid(0, +grid_move_offset)

	elif Input.is_key_pressed(KEY_SHIFT) and event.keycode == KEY_TAB:
		_move_selection_on_grid(-grid_move_offset, 0)
	
	elif event.keycode == KEY_TAB:
		_move_selection_on_grid(+grid_move_offset, 0)

	elif ctrl_pressed and event.keycode == KEY_C:
		TextEditingUtilsClass.multi_copy(selection.edited_cells_text)
		get_viewport().set_input_as_handled()

	# Ctrl + V
	elif ctrl_pressed and event.keycode == KEY_V and editor_view.columns[column] != "resource_path":
		selection.clipboard_paste()
		get_viewport().set_input_as_handled()

	# TEXT CARET MOVEMENT
	var caret_move_offset := TextEditingUtilsClass.get_caret_movement_from_key(event.keycode)
	if TextEditingUtilsClass.multi_move_caret(caret_move_offset, selection.edited_cells_text, selection.edit_cursor_positions, ctrl_pressed):
		selection.queue_redraw()
		return

	# The following actions do not work on non-editable cells.
	if !selection.column_editors[column].is_text() or editor_view.columns[column] == "resource_path":
		return
	
	# ERASING
	elif event.keycode == KEY_BACKSPACE:
		editor_view.set_edited_cells_values_text(TextEditingUtilsClass.multi_erase_left(
			selection.edited_cells_text, selection.edit_cursor_positions, ctrl_pressed
		))

	elif event.keycode == KEY_DELETE:
		editor_view.set_edited_cells_values_text(TextEditingUtilsClass.multi_erase_right(
			selection.edited_cells_text, selection.edit_cursor_positions, ctrl_pressed
		))
		get_viewport().set_input_as_handled()

	# And finally, text typing.
	elif event.keycode == KEY_ENTER:
		editor_view.set_edited_cells_values_text(TextEditingUtilsClass.multi_input(
			"\n", selection.edited_cells_text, selection.edit_cursor_positions
		))

	elif event.unicode != 0 and event.unicode != 127:
		editor_view.set_edited_cells_values_text(TextEditingUtilsClass.multi_input(
			char(event.unicode), selection.edited_cells_text, selection.edit_cursor_positions
		))

	selection.queue_redraw()


func _move_selection_on_grid(move_h : int, move_v : int):
	var selected_cells := selection.edited_cells.duplicate()
	var num_columns := editor_view.columns.size()
	var num_rows := editor_view.rows.size()
	var new_child_pos := Vector2i(0, 0)
	for i in selected_cells.size():
		new_child_pos = Vector2i(
			clamp(selected_cells[i].x + move_h, 0, num_columns - 1),
			clamp(selected_cells[i].y + move_v, 0, num_rows - 1),
		)
		selected_cells[i] = new_child_pos

	editor_view.grab_focus()
	selection.deselect_all_cells()
	selection.select_cells(selected_cells)
