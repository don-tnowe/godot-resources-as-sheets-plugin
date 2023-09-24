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

var _textfield : LineEdit
var _textfield_ml : TextEdit
var _togglable_popup : PopupPanel


func _enter_tree():
	var toggle_button := Button.new()
	var popup_box := VBoxContainer.new()
	var popup_buttons_box := HBoxContainer.new()
	var title_label := Label.new()
	var submit_button := Button.new()
	_textfield = LineEdit.new()
	_togglable_popup = PopupPanel.new()
	_textfield_ml = TextEdit.new()

	add_child(_textfield)
	add_child(toggle_button)
	_textfield.add_child(_togglable_popup)
	_togglable_popup.add_child(popup_box)
	popup_box.add_child(title_label)
	popup_box.add_child(_textfield_ml)
	popup_box.add_child(popup_buttons_box)
	popup_buttons_box.add_child(submit_button)

	title_label.text = title

	toggle_button.icon = get_theme_icon("Collapse", "EditorIcons")
	toggle_button.pressed.connect(_on_expand_pressed)

	submit_button.text = "Run multiline!"
	submit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit_button.pressed.connect(_on_text_submitted)

	_textfield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_textfield.text_submitted.connect(_on_text_submitted.unbind(1))

	_textfield_ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_textfield_ml.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _on_expand_pressed():
	_togglable_popup.popup(Rect2i(_textfield.get_screen_position(), Vector2(size.x, 256.0)))



func _on_text_submitted():
	[_table_filter, _table_process][mode].call()


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
	editor_view.search_cond = new_script
	editor_view.refresh()


func _table_process():
	var new_script := GDScript.new()
	new_script.source_code = _get_script_source_code("static func get_result(value, res, row_index, cell_index):\n")
	new_script.reload()

	var editor_view := get_node(editor_view_path)
	var new_script_instance = new_script.new()
	var values = editor_view.get_edited_cells_values()
	var cur_row := 0

	var edited_rows = editor_view._selection.get_edited_rows()
	for i in values.size():
		values[i] = new_script_instance.get_result(values[i], editor_view.rows[edited_rows[i]], edited_rows[i], i)

	editor_view.set_edited_cells_values(values)
