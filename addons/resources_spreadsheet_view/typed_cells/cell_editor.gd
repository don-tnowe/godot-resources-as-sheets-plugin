class_name ResourceTablesCellEditor
extends RefCounted

const TextEditingUtilsClass := preload("uid://cl0y7kaefmwpj")
const TablesPluginSettingsClass := preload("uid://8topi2360xak")

const CELL_SCENE_DIR := "res://addons/resources_spreadsheet_view/typed_cells/"

static var editor_text_color := Color.WHITE
static var tint_to_default_text_strength := 0.0
static var tint_to_default_text_strength_updated_time := 0

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

## Override to refresh internal text values when edited using keyboard.
func text_update_on_edit():
	return false

## Override to define custom behaviour for converting the value into text for editing and copy/paste.
func to_text(value) -> String:
	return var_to_str(value)

## Override to define custom behaviour for converting the value from text for editing and copy/paste.
func from_text(text : String):
	return str_to_var(text)

## Override to change behaviour when there are color cells to the left of this cell.
func set_color(node : Control, color : Color):
	node.get_node("Back").modulate = color * 1.0


static func text_to_random_color(value : String) -> Color:
	if Time.get_ticks_msec() - tint_to_default_text_strength_updated_time > 0.6:
		var color_tint : float = 0.01 * ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "array_color_tint", 100.0)
		tint_to_default_text_strength = color_tint
		tint_to_default_text_strength_updated_time = Time.get_ticks_msec()
		editor_text_color = Engine.get_singleton("EditorInterface").get_editor_theme().get_color("font_color", "Editor")

	var result := Color(value.hash())
	result.v = lerp(result.v, 1.0, 0.5)
	result.a = 1.0
	result = result.blend(Color(editor_text_color, 1.0 - tint_to_default_text_strength))
	return result
