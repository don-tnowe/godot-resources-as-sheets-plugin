class_name CellEditor
extends Reference

const CELL_SCENE_DIR = "res://addons/resources_speadsheet_view/typed_cells/"


# Override to define where the cell should be shown.
func can_edit_value(value, type, property_hint) -> bool:
	return true

# Override to change how the cell is created; preload a scene or create nodes from code.
# Caller is an instance of `editor_view.tscn`.
func create_cell(caller : Control) -> Control:
	return load(CELL_SCENE_DIR + "basic.tscn").instance()

# Override to change behaviour when the cell is clicked to be selected.
func set_selected(node : Control, selected : bool):
  node.get_node("Selected").visible = selected

# Override to change behaviour when the cell is edited via keyboard.
func set_value(node : Control, value):
	node.text = TextEditingUtils.show_non_typing(str(value))


func get_text_value(node : Control):
	return node.text

# Override for text-based types to allow multi-editing.
func get_text_length(node : Control):
	return node.text.length()


func set_color(node : Control, color : Color):
	node.get_node("Back").modulate = color * 1.0
