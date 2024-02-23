class_name ResourceTablesEditFormatTres
extends ResourceTablesEditFormat

var timer : SceneTreeTimer


func get_value(entry, key : String):
	return entry[key]


func set_value(entry, key : String, value, index : int):
	entry[key] = value


func save_entries(all_entries : Array, indices : Array, repeat : bool = true):
	# No need to save. Resources are saved with Ctrl+S
	# (likely because plugin.edit_resource is called to show inspector)
	return


func create_resource(entry) -> Resource:
	return entry


func duplicate_rows(rows : Array, name_input : String):
	if rows.size() == 1:
		var new_row = rows[0].duplicate()
		new_row.resource_path = rows[0].resource_path.get_base_dir() + "/" + name_input + ".tres"
		ResourceSaver.save(new_row)
		return

	var new_row
	for x in rows:
		new_row = x.duplicate()
		new_row.resource_path = x.resource_path.get_basename() + name_input + ".tres"
		ResourceSaver.save(new_row)


func rename_row(row, new_name : String):
	var new_row = row
	DirAccess.open("res://").remove(row.resource_path)
	new_row.resource_path = row.resource_path.get_base_dir() + "/" + new_name + ".tres"
	ResourceSaver.save(new_row)


func delete_rows(rows):
	for x in rows:
		DirAccess.open("res://").remove(x.resource_path)


func has_row_names():
	return true


func import_from_path(folderpath : String, insert_func : Callable, sort_by : String, sort_reverse : bool = false) -> Array:
	var rows := []
	var dir := DirAccess.open(folderpath)
	if dir == null: return []

	var file_stack : Array[String] = []
	var folder_stack : Array[String] = [folderpath]

	while folder_stack.size() > 0:
		folderpath = folder_stack.pop_back()

		for x in DirAccess.get_files_at(folderpath):
			file_stack.append(folderpath.path_join(x))

		for x in DirAccess.get_directories_at(folderpath):
			folder_stack.append(folderpath.path_join(x))

	var loaded_res : Array[Resource] = []
	var res : Resource = null
	var cur_dir_types : Dictionary = {}
	loaded_res.resize(file_stack.size())
	for i in file_stack.size():
		res = null
		if file_stack[i].ends_with(".tres"):
			res = load(file_stack[i])
			loaded_res[i] = res

	editor_view.fill_property_data_many(loaded_res)
	for x in loaded_res:
		if x == null: continue
		insert_func.call(x, rows, sort_by, sort_reverse)

	return rows
