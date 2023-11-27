@tool
extends MarginContainer

enum {
	EDITBOX_DUPLICATE = 1,
	EDITBOX_RENAME,
	EDITBOX_DELETE,
}

const TextEditingUtilsClass := preload("res://addons/resources_spreadsheet_view/text_editing_utils.gd")
const TablesPluginSettingsClass := preload("res://addons/resources_spreadsheet_view/settings_grid.gd")

@export @onready var editor_view := $"../.."
@export @onready var selection := $"../../SelectionManager"

@onready var editbox_node := $"Control/ColorRect/Popup"
@onready var editbox_label : Label = editbox_node.get_node("Panel/VBoxContainer/Label")
@onready var editbox_input : LineEdit = editbox_node.get_node("Panel/VBoxContainer/LineEdit")

var cell : Control
var editbox_action : int


func _ready():
	editbox_input.get_node("../..").add_theme_stylebox_override(
		"panel",
		get_theme_stylebox(&"Content", &"EditorStyles")
	)
	editbox_input.text_submitted.connect(func(_new_text): _on_editbox_accepted())
	close()


func _on_grid_cells_rightclicked(cells):
	open(cells)


func _on_grid_cells_selected(cells):
	open(cells, true, true)


func open(cells : Array, pin_to_cell : bool = false, from_leftclick : bool = false):
	if cells.size() == 0 or (from_leftclick and !ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "context_menu_on_leftclick")):
		hide()
		cell = null
		return
	
	if pin_to_cell:
		cell = cells[-1]
		set_deferred(&"global_position", Vector2(
			cell.global_position.x + cell.size.x,
			cell.global_position.y
		))

	else:
		cell = null
		set_deferred(&"global_position", get_global_mouse_position() + Vector2.ONE)

	show()
	size = Vector2.ZERO
	top_level = true
	$"Control2/Label".text = str(cells.size()) + (" Cells" if cells.size() % 10 != 1 else " Cell")
	$"GridContainer/Rename".visible = editor_view.has_row_names()


func close():
	pass


func _input(event : InputEvent):
	if !editor_view.is_visible_in_tree():
		close()
		return

	if event is InputEventMouseButton and event.is_pressed():
		close()
		return

	if event is InputEventKey:
		if event.is_pressed() and event.is_command_or_control_pressed():
			global_position = get_global_mouse_position() + Vector2.ONE
			if cell != null:
				global_position = Vector2(
					cell.global_position.x + cell.size.x,
					cell.global_position.y
				)

			# Dupe
			if event.keycode == KEY_D:
				_on_Duplicate_pressed()
				return
			
			# Rename
			if event.keycode == KEY_R:
				_on_Rename_pressed()
				return



func _on_Duplicate_pressed():
	_show_editbox(EDITBOX_DUPLICATE)


func _on_CbCopy_pressed():
	TextEditingUtilsClass.multi_copy(selection.edited_cells_text)


func _on_CbPaste_pressed():
	editor_view.set_edited_cells_values(
		TextEditingUtilsClass.multi_paste(
			selection.edited_cells_text,
			selection.edit_cursor_positions
		)
	)


func _on_Rename_pressed():
	_show_editbox(EDITBOX_RENAME)


func _on_Delete_pressed():
	_show_editbox(EDITBOX_DELETE)


func _show_editbox(action):
	editbox_action = action
	match action:
		EDITBOX_DUPLICATE:
			if !editor_view.has_row_names():
				_on_editbox_accepted()
				return

			if selection.edited_cells.size() == 1:
				editbox_label.text = "Input new row's name..."
				editbox_input.text = editor_view.get_last_selected_row()\
					.resource_path.get_file().get_basename()

			else:
				editbox_label.text = "Input suffix to append to names..."
				editbox_input.text = ""

		EDITBOX_RENAME:
			editbox_label.text = "Input new name for row..."
			editbox_input.text = editor_view.get_last_selected_row()\
				.resource_path.get_file().get_basename()

		EDITBOX_DELETE:
			editbox_label.text = "Really delete selected rows? (Irreversible!!!)"
			editbox_input.text = editor_view.get_last_selected_row()\
				.resource_path.get_file().get_basename()
	
	show()
	editbox_input.grab_focus()
	editbox_input.caret_column = 999999999
	editbox_node.size = Vector2.ZERO
	editbox_node.show()
	$"Control/ColorRect".show()
	$"Control/ColorRect".top_level = true
	$"Control/ColorRect".size = get_viewport_rect().size * 4.0
	editbox_node.global_position = (
		global_position
		+ size * 0.5
		- editbox_node.get_child(0).size * 0.5
	)


func _on_editbox_closed():
	editbox_node.hide()
	$"Control/ColorRect".hide()


func _on_editbox_accepted():
	match(editbox_action):
		EDITBOX_DUPLICATE:
			editor_view.duplicate_selected_rows(editbox_input.text)

		EDITBOX_RENAME:
			editor_view.rename_row(editor_view.get_last_selected_row(), editbox_input.text)

		EDITBOX_DELETE:
			editor_view.delete_selected_rows()

	_on_editbox_closed()
