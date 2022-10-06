tool
extends HBoxContainer

export var path_editor_view_root := NodePath("")

# These can not be set externally.
var rows_per_page := 50 setget _set_none
var current_page := 0 setget _set_none
var first_row := 0 setget _set_none
var last_row := 50 setget _set_none


func _set_none(v): pass


func _on_Control_grid_updated():
	var root = get_node(path_editor_view_root)
	visible = true

	var page_count = (root.rows.size() - 1) / rows_per_page + 1
	first_row = min(current_page, page_count) * rows_per_page
	last_row = min(first_row + rows_per_page, root.rows.size())

	var pagelist_node = $"Pagelist"
	for x in pagelist_node.get_children():
		x.queue_free()
	
	var button_group = ButtonGroup.new()
	var btns = []
	btns.resize(page_count)
	for i in page_count:
		var btn = Button.new()
		btns[i] = btn
		btn.toggle_mode = true
		btn.group = button_group
		btn.text = str(i + 1)
		btn.connect("pressed", self, "_on_button_pressed", [btn])
		pagelist_node.add_child(btn)
			
	btns[current_page].pressed = true

	var sort_property = root.sorting_by
	if sort_property == "": sort_property = "resource_path"
	var sort_type = root.column_types[root.columns.find(sort_property)]
	var property_values = []
	property_values.resize(page_count)
	for i in page_count:
		property_values[i] = root.rows[i * rows_per_page].get(sort_property)

	if sort_type == TYPE_REAL or sort_type == TYPE_INT:
		for i in page_count:
			btns[i].text = str(property_values[i])
			
	elif sort_type == TYPE_COLOR:
		for i in page_count:
			btns[i].self_modulate = property_values[i] * 0.75 + Color(0.25, 0.25, 0.25, 1.0)
	
	elif sort_type == TYPE_STRING:
		var strings = []
		strings.resize(page_count)
		for i in page_count:
			strings[i] = property_values[i].get_file()
			if strings[i] == "":
				strings[i] = str(i)
			
		_fill_buttons_with_prefixes(btns, strings, page_count)
	
	elif sort_type == TYPE_OBJECT:
		var strings = []
		strings.resize(page_count + 1)
		for i in page_count:
			if is_instance_valid(property_values[i]):
				strings[i] = property_values[i].resource_path.get_file()
		
		_fill_buttons_with_prefixes(btns, strings, page_count)


func _fill_buttons_with_prefixes(btns, strings, page_count):
	for i in page_count:
		if i == 0:
			btns[0].text = strings[0][0]
			continue

		for j in strings[i].length():
			if strings[i].ord_at(j) != strings[i - 1].ord_at(j):
				btns[i].text = strings[i].left(j + 1)
				btns[i - 1].text = strings[i - 1].left(max(j + 1, btns[i - 1].text.length()))
				break
	
	for i in page_count - 1:
		btns[i].text = btns[i].text + "-" + btns[i + 1].text

	btns[page_count - 1].text += "-[End]"


func _on_button_pressed(button):
	button.pressed = true
	current_page = button.get_position_in_parent()
	_update_view()


func _on_LineEdit_value_changed(value):
	rows_per_page = value
	_update_view()


func _update_view():
	_on_Control_grid_updated()
	var view = get_node(path_editor_view_root)
	view.refresh(false)
