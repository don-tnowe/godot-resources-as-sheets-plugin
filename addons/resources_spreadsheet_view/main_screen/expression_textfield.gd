@tool
extends Control

@export var editor_view_path : NodePath

@export_enum("Filter", "Process", "Sort") var mode := 0
@export var title := ""
@export var default_text := "":
	set(v):
		default_text = v
		if _textfield == null:
			await ready

		_textfield.text = v
@export_multiline var default_text_ml := "":
	set(v):
		default_text_ml = v
		if _textfield_ml == null:
			await ready

		_textfield_ml.text = v
@export var function_save_key := ""

var _textfield : LineEdit
var _textfield_ml : TextEdit
var _togglable_popup : PopupPanel
var _saved_function_index_label : Label

var _saved_functions : Array = []
var _saved_function_selected := -1


func load_saved_functions(func_dict : Dictionary):
	if !func_dict.has(function_save_key):
		func_dict[function_save_key] = [default_text_ml]

	_saved_functions = func_dict[function_save_key]
	_on_saved_function_selected(0)


func _ready():
	var toggle_button := Button.new()
	var popup_box := VBoxContainer.new()
	var popup_buttons_box := HBoxContainer.new()
	var title_label := Label.new()
	var submit_button := Button.new()
	var move_label := Label.new()
	var move_button_l := Button.new()
	var move_button_r := Button.new()
	_textfield = LineEdit.new()
	_togglable_popup = PopupPanel.new()
	_textfield_ml = TextEdit.new()
	_saved_function_index_label = Label.new()

	add_child(_textfield)
	add_child(toggle_button)
	_textfield.add_child(_togglable_popup)
	_togglable_popup.add_child(popup_box)
	popup_box.add_child(title_label)
	popup_box.add_child(_textfield_ml)
	popup_box.add_child(popup_buttons_box)
	popup_buttons_box.add_child(submit_button)
	popup_buttons_box.add_child(move_label)
	popup_buttons_box.add_child(move_button_l)
	popup_buttons_box.add_child(_saved_function_index_label)
	popup_buttons_box.add_child(move_button_r)

	title_label.text = title

	toggle_button.icon = get_theme_icon("Collapse", "EditorIcons")
	toggle_button.pressed.connect(_on_expand_pressed)

	_textfield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_textfield.text_submitted.connect(_on_text_submitted.unbind(1))

	_textfield_ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_textfield_ml.size_flags_vertical = Control.SIZE_EXPAND_FILL

	submit_button.text = "Run multiline!"
	submit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit_button.pressed.connect(_on_text_submitted)

	move_label.text = "Choose saved:"
	move_button_l.icon = get_theme_icon("PagePrevious", "EditorIcons")
	move_button_l.pressed.connect(_on_saved_function_bumped.bind(-1))
	_on_saved_function_selected(0)
	move_button_r.icon = get_theme_icon("PageNext", "EditorIcons")
	move_button_r.pressed.connect(_on_saved_function_bumped.bind(+1))



func _on_expand_pressed():
	_togglable_popup.popup(Rect2i(_textfield.get_screen_position(), Vector2(size.x, 256.0)))


func _on_text_submitted():
	[_table_filter, _table_process][mode].call()
	_saved_functions[_saved_function_selected] = _textfield_ml.text
	get_node(editor_view_path).save_data.call_deferred()


func _get_script_source_code(first_line : String):
	var new_text := ""
	if !_togglable_popup.visible:
		new_text = _textfield.text
		if new_text == "":
			new_text = default_text

		return first_line + "\treturn " + new_text

	else:
		new_text = _textfield_ml.text
		if new_text == "":
			new_text = default_text_ml

		var text_split := new_text.split("\n")
		for i in text_split.size():
			text_split[i] = "\t" + text_split[i]

		return first_line + "\n".join(text_split)


func _table_filter():
	var new_script := GDScript.new()
	new_script.source_code = _get_script_source_code("static func can_show(res, index):\n")
	new_script.reload()

	var editor_view := get_node(editor_view_path)
	editor_view.search_cond = new_script.can_show
	editor_view.refresh()


func _table_process():
	var new_script := GDScript.new()
	new_script.source_code = _get_script_source_code("static func get_result(value, res, all_res, row_index):\n")
	new_script.reload()

	var editor_view := get_node(editor_view_path)
	var new_script_instance := new_script.new()
	var values : Array = editor_view.get_edited_cells_values()

	var edited_rows : Array[int] = editor_view._selection.get_edited_rows()
	var edited_resources := edited_rows.map(func(x): return editor_view.rows[x])
	for i in values.size():
		values[i] = new_script_instance.get_result(values[i], editor_view.rows[edited_rows[i]], edited_resources, i)

	editor_view.set_edited_cells_values(values)


func _on_saved_function_selected(new_index : int):
	if new_index < 0:
		new_index = 0

	if _saved_function_selected == _saved_functions.size() - 1 and _textfield_ml.text == default_text_ml:
		_saved_functions.resize(_saved_functions.size() - 1)

	elif _saved_function_selected >= 0:
		_saved_functions[_saved_function_selected] = _textfield_ml.text

	_saved_function_selected = new_index
	if new_index >= _saved_functions.size():
		_saved_functions.resize(new_index + 1)
		for i in _saved_functions.size():
			if _saved_functions[i] == null:
				_saved_functions[i] = default_text_ml

	_textfield_ml.text = _saved_functions[new_index]
	_saved_function_index_label.text = "%d/%d" % [new_index + 1, _saved_functions.size()]
	get_node(editor_view_path).save_data.call_deferred()


func _on_saved_function_bumped(increment : int):
	_on_saved_function_selected(_saved_function_selected + increment)
