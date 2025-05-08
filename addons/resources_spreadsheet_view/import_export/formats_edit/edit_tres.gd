class_name ResourceTablesEditFormatTres
extends ResourceTablesEditFormat

var timer : SceneTreeTimer


func get_value(entry, key : String):
	return entry[key]


func set_value(entry, key : String, value, index : int):
	var prev_value = entry[key]
	if prev_value is StringName:
		entry[key] = StringName(value)
		return

	if prev_value is String:
		entry[key] = String(value)
		return

	if prev_value is float:
		entry[key] = float(value)
		return

	if prev_value is int:
		entry[key] = int(value)
		return

	entry[key] = value

func save_entries(all_entries : Array, indices : Array, repeat : bool = true):
	# No need to save. Resources are saved with Ctrl+S
	# (likely because plugin.edit_resource is called to show inspector)
	return


func create_resource(entry) -> Resource:
	return entry


func duplicate_rows(rows : Array, name_input : String):
	var new_path := ""
	if rows.size() == 1:
		var new_row = rows[0].duplicate()
		var res_extension := ".res" if rows[0].resource_path.ends_with(".res") else ".tres"
		new_path = rows[0].resource_path.get_base_dir() + "/" + name_input + res_extension
		while ResourceLoader.exists(new_path):
			new_path = new_path.trim_suffix(res_extension) + "_copy" + res_extension

		new_row.resource_path = new_path
		ResourceSaver.save(new_row)
		return

	var new_row
	for x in rows:
		new_row = x.duplicate()
		var res_extension := ".res" if x.resource_path.ends_with(".res") else ".tres"
		new_path = x.resource_path.get_basename() + name_input + res_extension
		while ResourceLoader.exists(new_path):
			new_path = new_path.trim_suffix(res_extension) + "_copy" + res_extension

		new_row.resource_path = new_path
		ResourceSaver.save(new_row)


func rename_row(row, new_name : String):
	var res_extension : String = ".res" if row.resource_path.ends_with(".res") else ".tres"
	var new_path : String = row.resource_path.get_base_dir() + "/" + new_name + res_extension
	while FileAccess.file_exists(new_path):
		new_path = new_path.trim_suffix(res_extension) + "_copy" + res_extension

	var new_row = row
	DirAccess.open("res://").remove(row.resource_path)
	new_row.resource_path = new_path
	ResourceSaver.save(new_row)


func delete_rows(rows):
	for x in rows:
		DirAccess.open("res://").remove(x.resource_path)


func has_row_names():
	return true


func import_from_path(folderpath : String, insert_func : Callable, sort_by : String, sort_reverse : bool = false) -> Array:
	var solo_property := ""
	var solo_property_split : Array[String] = []
	if folderpath.contains("::"):
		var found_at := folderpath.find("::")
		solo_property = folderpath.substr(found_at + "::".length()).trim_suffix("/")
		folderpath = folderpath.left(found_at)
		for x in solo_property.split("::"):
			solo_property_split.append(x)

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

	var loaded_res_unique := {}
	for x in file_stack:
		if !x.ends_with(".tres") and !x.ends_with(".res"):
			continue

		if solo_property.is_empty():
			loaded_res_unique[load(x)] = true

		else:
			_append_soloed_property(load(x), loaded_res_unique, solo_property_split)

	for x in loaded_res_unique.keys():
		if x == null: continue
		insert_func.call(x, rows, sort_by, sort_reverse)

	editor_view.fill_property_data_many(loaded_res_unique.keys())
	return rows


func _append_soloed_property(current_res : Resource, result : Dictionary, solo_property_split : Array[String], solo_property_split_idx : int = -solo_property_split.size()):
	var soloed_value = current_res[solo_property_split[solo_property_split_idx]]
	if solo_property_split_idx == -1:
		if soloed_value is Resource:
			result[soloed_value] = true

		elif soloed_value is Array:
			for x in soloed_value:
				result[x] = true

	else:
		if soloed_value is Resource:
			_append_soloed_property(soloed_value, result, solo_property_split, solo_property_split_idx + 1)

		elif soloed_value is Array:
			for x in soloed_value:
				_append_soloed_property(x, result, solo_property_split, solo_property_split_idx + 1)