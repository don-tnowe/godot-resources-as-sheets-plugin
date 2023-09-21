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

	editor_view.remembered_paths.clear()
	var cur_dir_types : Dictionary = {}

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
	loaded_res.resize(file_stack.size())
	for i in file_stack.size():
		res = null
		if file_stack[i].ends_with(".tres"):
			res = load(file_stack[i])
			loaded_res[i] = res
			cur_dir_types[res.get_class()] = cur_dir_types.get(res.get_class(), 0) + 1
			var res_script := res.get_script()
			if res_script != null:
				cur_dir_types[res_script] = cur_dir_types.get(res_script, 0) + 1

		editor_view.remembered_paths[file_stack[i]] = res

	var most_count_key = null
	var most_count_count := 0
	var most_count_is_base_class := false
	for k in cur_dir_types:
		var v : int = cur_dir_types[k]
		if v > most_count_count || (v >= most_count_count && most_count_is_base_class):
			most_count_key = k
			most_count_count = v
			most_count_is_base_class = k is String

	var first_loadable_found := false
	for x in loaded_res:
		if x == null: continue
		if !first_loadable_found:
			first_loadable_found = true
			editor_view.fill_property_data(x)
			if !(sort_by in x):
				sort_by = "resource_path"

		if most_count_is_base_class:
			if x.get_class() == most_count_key:
				insert_func.call(x, rows, sort_by, sort_reverse)

		elif x.get_script() == most_count_key:
			insert_func.call(x, rows, sort_by, sort_reverse)

	return rows
