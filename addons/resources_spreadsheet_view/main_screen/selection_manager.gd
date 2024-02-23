@tool
extends Control

signal cells_selected(cells)
signal cells_rightclicked(cells)

const EditorViewClass = preload("res://addons/resources_spreadsheet_view/editor_view.gd")

@export var cell_editor_classes : Array[Script] = []

@export @onready var node_property_editors : VBoxContainer = $"../HeaderContentSplit/MarginContainer/FooterContentSplit/Footer/PropertyEditors"
@export @onready var scrollbar : ScrollContainer = $"../HeaderContentSplit/MarginContainer/FooterContentSplit/Panel/Scroll"

@onready var editor_view : EditorViewClass = get_parent()

var edited_cells : Array = []
var edited_cells_text : Array = []
var edit_cursor_positions : Array[int] = []

var all_cell_editors : Array = []
var column_editors : Array[Object] = []
var inspector_resource : Resource


func _ready():
	# Load cell editors and instantiate them
	for x in cell_editor_classes:
		all_cell_editors.append(x.new())
		all_cell_editors[all_cell_editors.size() - 1].hint_strings_array = editor_view.column_hint_strings

	get_parent()\
		.editor_interface\
		.get_inspector()\
		.property_edited\
		.connect(_on_inspector_property_edited)

	scrollbar.get_h_scroll_bar().value_changed.connect(queue_redraw.unbind(1), CONNECT_DEFERRED)
	scrollbar.get_v_scroll_bar().value_changed.connect(queue_redraw.unbind(1), CONNECT_DEFERRED)


func _draw():
	var font := get_theme_font("font", "Label")
	var font_size := get_theme_font_size("font", "Label")
	var label_padding_left := 2.0
	var newline_char := 10
	if edit_cursor_positions.size() != edited_cells.size():
		return

	for i in edited_cells.size():
		if edit_cursor_positions[i] >= edited_cells_text[i].length():
			continue

		var char_size := Vector2(0, font.get_ascent(font_size))
		var cursor_pos := Vector2(label_padding_left, 0)
		var cell_text : String = edited_cells_text[i]
		var cell : Control = edited_cells[i]
		if cell is Label and cell.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
			cursor_pos.x += cell.size.x - font.get_multiline_string_size(edited_cells[i].text, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size).x

		for j in max(edit_cursor_positions[i], 0) + 1:
			if j == 0: continue
			if cell_text.unicode_at(j - 1) == newline_char:
				cursor_pos.x = label_padding_left
				cursor_pos.y += font.get_ascent(font_size)
				continue

			char_size = font.get_char_size(cell_text.unicode_at(j - 1), font_size)
			cursor_pos.x += char_size.x

		draw_rect(Rect2(cursor_pos + cell.global_position - global_position, Vector2(2, char_size.y)), Color(1, 1, 1, 0.5))


func initialize_editors(column_values, column_types, column_hints):
	deselect_all_cells()
	edited_cells.clear()
	edited_cells_text.clear()
	edit_cursor_positions.clear()

	column_editors.clear()
	for i in column_values.size():
		for x in all_cell_editors:
			if x.can_edit_value(column_values[i], column_types[i], column_hints[i], i):
				column_editors.append(x)
				break


func deselect_all_cells():
	for x in edited_cells:
		column_editors[get_cell_column(x)].set_selected(x, false)

	edited_cells.clear()
	edited_cells_text.clear()
	edit_cursor_positions.clear()
	_selection_changed()


func deselect_cell(cell : Control):
	var idx := edited_cells.find(cell)
	if idx == -1: return

	column_editors[get_cell_column(cell)].set_selected(cell, false)
	edited_cells.remove_at(idx)
	if edited_cells_text.size() != 0:
		edited_cells_text.remove_at(idx)
		edit_cursor_positions.remove_at(idx)
		
	_selection_changed()


func select_cell(cell : Control):
	var column_index := get_cell_column(cell)
	if can_select_cell(cell):
		_add_cell_to_selection(cell)
		_try_open_docks(cell)
		inspector_resource = editor_view.rows[get_cell_row(cell)]
		# inspector_resource = editor_view.rows[get_cell_row(cell)].duplicate()
		# inspector_resource.resource_path = ""
		editor_view.editor_plugin.get_editor_interface().edit_resource(inspector_resource)

	_selection_changed()


func select_cells(cells : Array):
	var last_selectible : Control = null
	for x in cells:
		if x.mouse_filter != MOUSE_FILTER_IGNORE and can_select_cell(x):
			_add_cell_to_selection(x)
			last_selectible = x

	if last_selectible != null:
		select_cell(last_selectible)


func select_cells_to(cell : Control):
	var column_index := get_cell_column(cell)
	if edited_cells.size() == 0 or column_index != get_cell_column(edited_cells[edited_cells.size() - 1]):
		return
	
	var row_start := get_cell_row(edited_cells[edited_cells.size() - 1]) - editor_view.first_row
	var row_end := get_cell_row(cell) - editor_view.first_row
	var edge_shift := -1 if row_start > row_end else 1
	row_start += edge_shift
	row_end += edge_shift

	for i in range(row_start, row_end, edge_shift):
		var cur_cell : Control = editor_view.node_table_root.get_child(i * editor_view.columns.size() + column_index)
		if !cur_cell.visible or cur_cell.mouse_filter == MOUSE_FILTER_IGNORE:
			# When search is active, some cells will be hidden.
			# When showing several classes, empty cells will be non-selectable.
			continue

		column_editors[column_index].set_selected(cur_cell, true)
		if !cur_cell in edited_cells:
			edited_cells.append(cur_cell)
			if column_editors[column_index].is_text():
				edited_cells_text.append(str(cur_cell.text))
				edit_cursor_positions.append(cur_cell.text.length())

	_selection_changed()


func rightclick_cells():
	cells_rightclicked.emit(edited_cells)


func can_select_cell(cell : Control) -> bool:
	if edited_cells.size() == 0:
		return true

	if (
		get_cell_column(cell)
		!= get_cell_column(edited_cells[0])
	):
		return false

	return !cell in edited_cells


func get_cell_column(cell : Control) -> int:
	return cell.get_index() % editor_view.columns.size()


func get_cell_row(cell : Control) -> int:
	return cell.get_index() / editor_view.columns.size() + editor_view.first_row


func get_edited_rows() -> Array[int]:
	var rows : Array[int] = []
	rows.resize(edited_cells.size())
	for i in rows.size():
		rows[i] = get_cell_row(edited_cells[i])

	return rows


func _selection_changed():
	queue_redraw()
	cells_selected.emit(edited_cells)


func _add_cell_to_selection(cell : Control):
	var column_editor = column_editors[get_cell_column(cell)]
	column_editor.set_selected(cell, true)
	edited_cells.append(cell)
	if column_editor.is_text():
		edited_cells_text.append(str(cell.text))
		edit_cursor_positions.append(cell.text.length())


func _update_selected_cells_text():
	if edited_cells_text.size() == 0:
		return

	var column_dtype : int = editor_view.column_types[get_cell_column(edited_cells[0])]
	for i in edited_cells.size():
		edited_cells_text[i] = editor_view.try_convert(edited_cells[i].text, column_dtype)
		edit_cursor_positions[i] = edited_cells_text[i].length()


func _try_open_docks(cell : Control):
	var column_index = get_cell_column(cell)
	var row = editor_view.rows[get_cell_row(cell)]
	var column = editor_view.columns[column_index]
	var type = editor_view.column_types[column_index]
	var hints = editor_view.column_hints[column_index]

	for x in node_property_editors.get_children():
		x.visible = x.try_edit_value(editor_view.io.get_value(row, column), type, hints)
		x.get_node(x.path_property_name).text = column


func _on_inspector_property_edited(property : String):
	if !editor_view.is_visible_in_tree(): return
	if inspector_resource == null: return
	
	if editor_view.columns[get_cell_column(edited_cells[0])] != property:
		var columns := editor_view.columns
		var previously_edited = edited_cells.duplicate()
		var new_column := columns.find(property)
		deselect_all_cells()
		var index := 0
		for i in previously_edited.size():
			index = get_cell_row(previously_edited[i]) * columns.size() + new_column
			_add_cell_to_selection(editor_view.node_table_root.get_child(index - editor_view.first_row))

	var values = []
	values.resize(edited_cells.size())
	values.fill(inspector_resource[property])

	editor_view.set_edited_cells_values.call_deferred(values)
	_try_open_docks(edited_cells[0])
