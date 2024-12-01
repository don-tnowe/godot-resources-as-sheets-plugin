@tool
extends OptionButton

@onready var editor_view := $"../../../../.."

var recent_paths := []


func _ready():
	item_selected.connect(_on_item_selected)


func load_paths(paths):
	clear()
	for x in paths:
		add_path_to_recent(x, true)

	selected = 0


func add_path_to_recent(path : String, is_loading : bool = false):
	if path in recent_paths: return

	var idx_in_array := recent_paths.find(path)
	if idx_in_array != -1:
		remove_item(idx_in_array)
		recent_paths.remove_at(idx_in_array)
	
	recent_paths.append(path)
	add_item(path)
	select(get_item_count() - 1)

	if !is_loading:
		editor_view.save_data()


func remove_selected_path_from_recent():
	if get_item_count() == 0:
		return
	
	var idx_in_array := selected
	recent_paths.remove_at(idx_in_array)
	remove_item(idx_in_array)

	if get_item_count() != 0:
		select(0)
		editor_view.display_folder(recent_paths[0])
		editor_view.save_data()


func _on_item_selected(index : int):
	editor_view.current_path = recent_paths[index]
	editor_view.node_folder_path.text = recent_paths[index]
	editor_view.refresh()
