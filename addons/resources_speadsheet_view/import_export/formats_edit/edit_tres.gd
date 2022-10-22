class_name SpreadsheetEditFormatTres
extends SpreadsheetEditFormat


func get_value(entry, key : String):
	return entry.get(key)


func set_value(entry, key : String, value, index : int):
	entry.set(key, value)
	

func save_entries(all_entries : Array, indices : Array):
	for x in indices:
		ResourceSaver.save(all_entries[x].resource_path, all_entries[x])


func create_resource(entry) -> Resource:
	return entry


func import_from_path(folderpath : String, insert_func : FuncRef, sort_by : String, sort_reverse : bool = false) -> Array:
	var rows := []
	var dir := Directory.new()
	dir.open(folderpath)
	dir.list_dir_begin()

	editor_view.remembered_paths.clear()
	var cur_dir_script : Script = null

	var filepath = dir.get_next()
	var res : Resource

	while filepath != "":
		if filepath.ends_with(".tres"):
			filepath = folderpath + filepath
			res = load(filepath)
			if !is_instance_valid(cur_dir_script):
				editor_view.fill_property_data(res)
				cur_dir_script = res.get_script()
				if !(sort_by in res):
					sort_by = "resource_path"

			if res.get_script() == cur_dir_script:
				insert_func.call_func(res, rows, sort_by, sort_reverse)
				editor_view.remembered_paths[res.resource_path] = res
		
		filepath = dir.get_next()

	return rows
