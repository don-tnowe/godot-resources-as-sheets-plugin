@tool
extends HBoxContainer

@onready var node_editor_view_root : Control = $"../../../.."

var rows_per_page := 50
var current_page := 0


func update_page_count(array : Array) -> int:
	var page_count : int = (node_editor_view_root.rows.size() - 1) / rows_per_page + 1
	node_editor_view_root.first_row = min(current_page, page_count) * rows_per_page
	node_editor_view_root.last_row = min(node_editor_view_root.first_row + rows_per_page, array.size())
	return page_count


func _on_grid_updated():
	if node_editor_view_root.rows.size() == 0:
		return

	visible = true
	var page_count := update_page_count(node_editor_view_root.rows)
	var pagelist_node := $"Scroll/Pagelist"
	for x in pagelist_node.get_children():
		x.queue_free()
	
	var button_group := ButtonGroup.new()
	var btns := []
	btns.resize(page_count)
	for i in page_count:
		var btn := Button.new()
		btns[i] = btn
		btn.toggle_mode = true
		btn.button_group = button_group
		btn.text = str(i + 1)
		btn.pressed.connect(_on_button_pressed.bind(btn))
		btn.size_flags_vertical = SIZE_SHRINK_CENTER
		pagelist_node.add_child(btn)

	var pagelist_line := HSeparator.new()
	pagelist_line.size_flags_horizontal = SIZE_EXPAND_FILL
	pagelist_node.add_child(pagelist_line)
	btns[current_page].button_pressed = true

	var sort_property : StringName = node_editor_view_root.sorting_by
	if sort_property == "": sort_property = "resource_path"
	var sort_type : int = node_editor_view_root.column_types[node_editor_view_root.columns.find(sort_property)]
	var property_values := []
	property_values.resize(page_count)
	if(node_editor_view_root.rows.size() == 0):
		return

	for i in page_count:
		property_values[i] = node_editor_view_root.rows[i * rows_per_page].get(sort_property)

	if sort_type == TYPE_FLOAT or sort_type == TYPE_INT:
		for i in page_count:
			btns[i].text = str(property_values[i])
			
	elif sort_type == TYPE_COLOR:
		for i in page_count:
			btns[i].self_modulate = property_values[i] * 0.75 + Color(0.25, 0.25, 0.25, 1.0)
	
	elif sort_type == TYPE_STRING:
		var strings := []
		strings.resize(page_count)
		for i in page_count:
			strings[i] = property_values[i].get_file()
			if strings[i] == "":
				strings[i] = str(i)
			
		_fill_buttons_with_prefixes(btns, strings, page_count)
	
	elif sort_type == TYPE_OBJECT:
		var strings := []
		strings.resize(page_count + 1)
		for i in page_count:
			if is_instance_valid(property_values[i]):
				strings[i] = property_values[i].resource_path.get_file()
		
		_fill_buttons_with_prefixes(btns, strings, page_count)


func _fill_buttons_with_prefixes(btns : Array, strings : Array, page_count : int):
	for i in page_count:
		if strings[i] == null:
			continue

		if i == 0:
			btns[0].text = strings[0][0]
			continue

		for j in strings[i].length():
			if strings[i].unicode_at(j) != strings[i - 1].unicode_at(j):
				btns[i].text = strings[i].left(j + 1)
				btns[i - 1].text = strings[i - 1].left(max(j + 1, btns[i - 1].text.length()))
				break
	
	for i in page_count - 1:
		btns[i].text = btns[i].text + "-" + btns[i + 1].text

	btns[page_count - 1].text += "-[End]"


func _on_button_pressed(button):
	button.button_pressed = true
	current_page = button.get_index()
	_update_view()


func _on_LineEdit_value_changed(value):
	rows_per_page = value
	current_page = 0
	_update_view()


func _update_view():
	node_editor_view_root.refresh(false)
