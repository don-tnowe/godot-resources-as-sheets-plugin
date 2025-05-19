@tool
extends ColorRect

const TablesPluginSettingsClass := preload("res://addons/resources_spreadsheet_view/settings_grid.gd")

@onready var editor_view : Control = $"../../../../../.."
@onready var grid_scroll : ScrollContainer = $"../../Scroll"
@onready var grid : Container = $"../../Scroll/MarginContainer/TableGrid"

var children : Array[Control] = []
var children_copy_cells : Array[Control] = []


func _ready() -> void:
	grid_scroll.get_h_scroll_bar().value_changed.connect(_on_scroll_updated, CONNECT_DEFERRED)
	grid_scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_updated, CONNECT_DEFERRED)


func _on_grid_updated() -> void:
	if editor_view.rows.size() == 0:
		hide()
		return

	visible = ProjectSettings.get_setting(TablesPluginSettingsClass.PREFIX + "freeze_first_column")
	for x in get_children():
		x.queue_free()

	children.clear()
	children_copy_cells.clear()
	size.x = 0.0

	await get_tree().process_frame

	var first_visible_column := 0
	for i in editor_view.columns.size():
		if grid.get_child(i).visible:
			first_visible_column = i
			break

	var total_column_count : int = editor_view.columns.size()
	children.resize(grid.get_child_count() / total_column_count)
	children_copy_cells.resize(children.size())
	for i in children.size():
		children_copy_cells[i] = grid.get_child(total_column_count * i + first_visible_column)
		children[i] = children_copy_cells[i].duplicate()
		children[i].mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(children[i])
		size.x = maxf(size.x, children_copy_cells[i].size.x)

	size.y = grid.size.y
	color = get_theme_color(&"background", &"Editor")
	color.a *= 0.9
	_on_scroll_updated(0.0)


func _on_scroll_updated(_new_value : float):
	position = Vector2(0.0, -grid_scroll.scroll_vertical)
	for i in children.size():
		children[i].size = children_copy_cells[i].size
		children[i].position = children_copy_cells[i].position
