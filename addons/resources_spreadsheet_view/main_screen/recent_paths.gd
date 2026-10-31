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

	selected = recent_paths.size() - 1


func reload_paths():
	var path_count = recent_paths.size()
	var removed = 0
	for x in path_count - removed:	
		x -= removed
		if !DirAccess.dir_exists_absolute(recent_paths[x]):
			removed += 1
			remove_path_from_recent(x)


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

func pressed():
	remove_path_from_recent(selected)

func remove_path_from_recent(index : int):
	if get_item_count() == 0:
		return
	
	recent_paths.remove_at(index)
	remove_item(index)

	if get_item_count() != 0:
		select(0)
		editor_view.display_folder(recent_paths[0])
		editor_view.save_data()


func _on_item_selected(index : int):
	editor_view.current_path = recent_paths[index]
	editor_view.node_folder_path.text = recent_paths[index]
	editor_view.refresh()


func _on_delete_path_pressed() -> void:
	pass # Replace with function body.
