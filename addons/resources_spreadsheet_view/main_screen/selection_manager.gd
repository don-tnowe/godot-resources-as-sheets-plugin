@tool
extends Control

signal cells_selected(cells_positions)
signal cells_rightclicked(cells_positions)

const EditorViewClass := preload("res://addons/resources_spreadsheet_view/editor_view.gd")
const TextEditingUtilsClass := preload("res://addons/resources_spreadsheet_view/text_editing_utils.gd")

@export var cell_editor_classes : Array[Script] = []

@onready var node_property_editors : VBoxContainer = $"../HeaderContentSplit/MarginContainer/FooterContentSplit/Footer/PropertyEditors"
@onready var scrollbar : ScrollContainer = $"../HeaderContentSplit/MarginContainer/FooterContentSplit/Panel/Scroll"

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

	if ProjectSettings.get_setting(editor_view.TablesPluginSettingsClass.PREFIX + "fold_docks", false):
		for x in node_property_editors.get_children():
			x.resize_set_hidden(true)


func _draw():
	if edited_cells.size() == 0 or edit_cursor_positions.size() != edited_cells.size() or !column_editors[edited_cells[0].x].is_text():
		return

	var font := get_theme_font(&"font", &"Label")
	var font_size := get_theme_font_size(&"font", &"Label")
	var caret_color := get_theme_color(&"caret_color", &"LineEdit")
	var label_padding_left := 2.0
	var newline_char := 10
	for i in edited_cells.size():
		var cell : Control = get_cell_node_from_position(edited_cells[i])
		var caret_rect := Rect2()
		if cell.has_method(&"get_character_bounds"):
			if edited_cells_text[i].length() == edit_cursor_positions[i]:
				caret_rect = cell.get_character_bounds(edit_cursor_positions[i] - 1)
				caret_rect.position.x += caret_rect.size.x

			else:
				caret_rect = cell.get_character_bounds(edit_cursor_positions[i])

			caret_rect.size.x = 1.0

		else:
			caret_rect = TextEditingUtilsClass.get_caret_rect(edited_cells_text[i], edit_cursor_positions[i], font, font_size, label_padding_left, 1.0)

		caret_rect.position += cell.global_position - global_position
		draw_rect(caret_rect, caret_color)


func initialize_editors(column_values, column_types, column_hints):
	_set_visible_selected(false)
	column_editors.clear()
	for i in column_values.size():
		for x in all_cell_editors:
			if x.can_edit_value(column_values[i], column_types[i], column_hints[i], i):
				column_editors.append(x)
				break


func deselect_all_cells():
	_set_visible_selected(false)
	edited_cells.clear()
	edited_cells_text.clear()
	edit_cursor_positions.clear()
	_selection_changed()


func deselect_cell(cell : Vector2i):
	var idx := edited_cells.find(cell)
	if idx == -1: return

	edited_cells.remove_at(idx)
	if edited_cells_text.size() != 0:
		edited_cells_text.remove_at(idx)
		edit_cursor_positions.remove_at(idx)

	var cell_node := get_cell_node_from_position(cell)
	if cell_node != null:
		column_editors[get_cell_column(cell)].set_selected(cell_node, false)

	_selection_changed()


func select_cell(cell : Vector2i):
	var column_index := get_cell_column(cell)
	if edited_cells.size() == 0 or edited_cells[0].x == cell.x:
		_add_cell_to_selection(cell)
		_try_open_docks(cell)
		inspector_resource = editor_view.rows[get_cell_row(cell)]
		editor_view.editor_plugin.get_editor_interface().edit_resource(inspector_resource)

	_selection_changed()


func select_cells(cells : Array):
	var last_selectible := Vector2i(-1, -1)
	var started_empty := edited_cells.size() == 0
	for x in cells:
		if started_empty or edited_cells[0].x != x.x:
			_add_cell_to_selection(x)
			if get_cell_node_from_position(x) != null:
				last_selectible = x

	if last_selectible != Vector2i(-1, -1):
		select_cell(last_selectible)


func select_cells_to(cell : Vector2i):
	var column_index := get_cell_column(cell)
	if edited_cells.size() == 0 or column_index != get_cell_column(edited_cells[-1]):
		return
	
	var row_start := get_cell_row(edited_cells[-1])
	var row_end := get_cell_row(cell)
	var edge_shift := -1 if row_start > row_end else 1
	row_start += edge_shift
	row_end += edge_shift

	var column_editor := column_editors[column_index]
	for i in range(row_start, row_end, edge_shift):
		var cur_cell := Vector2i(column_index, i)
		var cur_cell_node := get_cell_node_from_position(cur_cell)
		if cur_cell not in edited_cells:
			edited_cells.append(cur_cell)

			var cur_cell_value = editor_view.io.get_value(editor_view.rows[cur_cell.y], editor_view.columns[cur_cell.x])
			var cur_cell_text : String = column_editor.to_text(cur_cell_value)
			edited_cells_text.append(cur_cell_text)
			edit_cursor_positions.append(cur_cell_text.length())

		if cur_cell_node == null or !cur_cell_node.visible or cur_cell_node.mouse_filter == MOUSE_FILTER_IGNORE:
			# When showing several classes, empty cells will be non-selectable.
			continue

		column_editors[column_index].set_selected(cur_cell_node, true)

	_selection_changed()


func rightclick_cells():
	cells_rightclicked.emit(edited_cells)


func is_cell_node_selected(cell : Control) -> bool:
	return get_cell_node_position(cell) in edited_cells


func is_cell_selected(cell : Vector2i) -> bool:
	return cell in edited_cells


func can_select_cell(cell : Vector2i) -> bool:
	if edited_cells.size() == 0:
		return true

	if (
		get_cell_column(cell)
		!= get_cell_column(edited_cells[0])
	):
		return false

	return !cell in edited_cells


func get_cell_node_from_position(cell_pos : Vector2i) -> Control:
	var cell_index := (cell_pos.y - editor_view.first_row) * editor_view.columns.size() + cell_pos.x
	if cell_index < 0 or cell_index >= editor_view.node_table_root.get_child_count():
		return null

	return editor_view.node_table_root.get_child(cell_index)


func get_cell_node_position(cell : Control) -> Vector2i:
	var col_count := editor_view.columns.size()
	var cell_index := cell.get_index()
	return Vector2i(cell_index % col_count, cell_index / col_count + editor_view.first_row)


func get_cell_column(cell : Vector2i) -> int:
	return cell.x


func get_cell_row(cell : Vector2i) -> int:
	return cell.y


func get_edited_rows() -> Array[int]:
	var rows : Array[int] = []
	rows.resize(edited_cells.size())
	for i in rows.size():
		rows[i] = get_cell_row(edited_cells[i])

	return rows


func clipboard_paste():
	if column_editors[edited_cells[0].x].is_text():
		editor_view.set_edited_cells_values(
			TextEditingUtilsClass.multi_paste(
				edited_cells_text,
				edit_cursor_positions,
			)
		)

	elif DisplayServer.clipboard_has():
		var values := []
		values.resize(edited_cells.size())
		var pasted_lines := DisplayServer.clipboard_get().replace("\r", "").split("\n")
		var paste_each_line := pasted_lines.size() == values.size()

		for i in values.size():
			values[i] = str_to_var(
				pasted_lines[i] if paste_each_line else DisplayServer.clipboard_get()
			)

		editor_view.set_edited_cells_values(values)


func _selection_changed():
	queue_redraw()
	cells_selected.emit(edited_cells)


func _set_visible_selected(state : bool):	
	for x in edited_cells:
		var cell_node := get_cell_node_from_position(x)
		if cell_node != null:
			column_editors[get_cell_column(x)].set_selected(cell_node, state)


func _add_cell_to_selection(cell : Vector2i):
	edited_cells.append(cell)

	var column_editor := column_editors[get_cell_column(cell)]
	var cell_node := get_cell_node_from_position(cell)
	if cell_node != null:
		column_editor.set_selected(cell_node, true)

	var cell_value = editor_view.io.get_value(editor_view.rows[cell.y], editor_view.columns[cell.x])
	var text_value : String = column_editor.to_text(cell_value)
	edited_cells_text.append(text_value)
	edit_cursor_positions.append(text_value.length())


func _update_selected_cells_text():
	if edited_cells_text.size() == 0:
		return

	var column_editor := column_editors[get_cell_column(edited_cells[0])]
	if !column_editor.text_update_on_edit():
		return

	for i in edited_cells.size():
		edited_cells_text[i] = column_editor.to_text(editor_view.io.get_value(
			editor_view.rows[edited_cells[i].y],
			editor_view.columns[edited_cells[i].x],
		))
		edit_cursor_positions[i] = edited_cells_text[i].length()


func _try_open_docks(cell : Vector2i):
	var column_index := get_cell_column(cell)
	var row = editor_view.rows[get_cell_row(cell)]
	var column := editor_view.columns[column_index]
	var type := editor_view.column_types[column_index]
	var hints := editor_view.column_hints[column_index]

	for x in node_property_editors.get_children():
		x.visible = x.try_edit_value(editor_view.io.get_value(row, column), type, hints)
		x.get_node(x.path_property_name).text = column


func _on_inspector_property_edited(property : StringName):
	if !editor_view.is_visible_in_tree(): return
	if inspector_resource != editor_view.editor_plugin.get_editor_interface().get_inspector().get_edited_object():
		return
	
	if editor_view.columns[get_cell_column(edited_cells[0])] != property:
		var columns := editor_view.columns
		var previously_edited := edited_cells.duplicate()
		var new_column := columns.find(property)
		deselect_all_cells()
		for i in previously_edited.size():
			_add_cell_to_selection(Vector2i(new_column, previously_edited[i].y))

	var new_value = inspector_resource[property]
	var values := []
	values.resize(edited_cells.size())
	values.fill(new_value)
	if new_value is Resource and new_value.resource_path == "":
		for i in values.size():
			values[i] = new_value.duplicate()

	editor_view.set_edited_cells_values.call_deferred(values)
	_try_open_docks(edited_cells[0])
