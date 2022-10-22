class_name SpreadsheetEditFormatTres
extends SpreadsheetEditFormat


func get_value(entry, key : String):
	return entry.get(key)


func set_value(entry, key : String, value):
	entry.set(key, value)
	

func save_entry(all_entries : Array, index : int):
	ResourceSaver.save(all_entries[index].resource_path, all_entries[index])


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
				editor_view.columns.clear()
				editor_view.column_types.clear()
				editor_view.column_hints.clear()
				editor_view.column_hint_strings.clear()
				editor_view.column_editors.clear()
				var column_index = -1
				for x in res.get_property_list():
					if x["usage"] & PROPERTY_USAGE_EDITOR != 0 and x["name"] != "script":
						column_index += 1
						editor_view.columns.append(x["name"])
						editor_view.column_types.append(x["type"])
						editor_view.column_hints.append(x["hint"])
						editor_view.column_hint_strings.append(x["hint_string"].split(","))
						for y in editor_view.all_cell_editors:
							if y.can_edit_value(get_value(res, x["name"]), x["type"], x["hint"], column_index):
								editor_view.column_editors.append(y)
								break
								
				cur_dir_script = res.get_script()
				if !(sort_by in res):
					sort_by = "resource_path"

			if res.get_script() == cur_dir_script:
				insert_func.call_func(res, rows, sort_by, sort_reverse)
				editor_view.remembered_paths[res.resource_path] = res
		
		filepath = dir.get_next()

	return rows
