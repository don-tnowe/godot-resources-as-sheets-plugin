class_name ResourceTablesCellEditor
extends RefCounted

const TextEditingUtilsClass := preload("res://addons/resources_spreadsheet_view/text_editing_utils.gd")

const CELL_SCENE_DIR = "res://addons/resources_spreadsheet_view/typed_cells/"

var hint_strings_array := []


## Override to define where the cell should be shown.
func can_edit_value(value, type, property_hint, column_index) -> bool:
	return value != null

## Override to change how the cell is created; preload a scene or create nodes from code.
## Caller is an instance of [code]editor_view.tscn[/code].
func create_cell(caller : Control) -> Control:
	return load(CELL_SCENE_DIR + "basic.tscn").instantiate()

## Override to change behaviour when the cell is clicked to be selected.
func set_selected(node : Control, selected : bool):
	node.get_node("Selected").visible = selected

## Override to change how the value is displayed.
func set_value(node : Control, value):
	node.text = TextEditingUtilsClass.show_non_typing(str(value))

## Override to prevent the cell from being edited as text.
func is_text():
	return true

## Override to change behaviour when there are color cells to the left of this cell.
func set_color(node : Control, color : Color):
	node.get_node("Back").modulate = color * 1.0
