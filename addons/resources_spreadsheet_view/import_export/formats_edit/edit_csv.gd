class_name SpreadsheetEditFormatCsv
extends SpreadsheetEditFormatTres

var import_data
var csv_rows = []
var resource_original_positions = {}
var timer : SceneTreeTimer


func get_value(entry, key : String):
	return entry.get(key)


func set_value(entry, key : String, value, index : int):
	entry.set(key, value)
	csv_rows[resource_original_positions[entry]] = import_data.resource_to_strings(entry)


func save_entries(all_entries : Array, indices : Array, repeat : bool = true):
	if timer == null || timer.time_left <= 0.0:
		var file = File.new()
		var space_after_delimeter = import_data.delimeter.ends_with(" ")
		file.open(import_data.edited_path, File.WRITE)
		for x in csv_rows:
			if space_after_delimeter:
				for i in x.size():
					if i == 0: continue
					x[i] = " " + x[i]

			file.store_csv_line(x, import_data.delimeter[0])
		
		file.close()
		if repeat:
			timer = editor_view.get_tree().create_timer(3.0)
			timer.connect("timeout", self, "save_entries", [all_entries, indices, false])


func create_resource(entry) -> Resource:
	return entry


func duplicate_rows(rows : Array, name_input : String):
	for x in rows:
		var new_res = x.duplicate()
		var index = resource_original_positions[x]
		csv_rows.insert(index, import_data.resource_to_strings(new_res))
		_bump_row_indices(index + 1, 1)
		resource_original_positions[new_res] = index + 1

	save_entries([], [])


func delete_rows(rows):
	for x in rows:
		var index = resource_original_positions[x]
		csv_rows.remove(index)
		_bump_row_indices(index, -1)
		resource_original_positions.erase(x)

	save_entries([], [])


func has_row_names():
	return false


func _bump_row_indices(from : int, increment : int = 1):
	for k in resource_original_positions:
		if resource_original_positions[k] >= from:
			resource_original_positions[k] += increment


func import_from_path(path : String, insert_func : FuncRef, sort_by : String, sort_reverse : bool = false) -> Array:
	import_data = load(path)
	var file = File.new()
	file.open(import_data.edited_path, File.READ)
	csv_rows = SpreadsheetImportFormatCsv.import_as_arrays(import_data)

	var rows := []
	var res : Resource
	resource_original_positions.clear()
	for i in csv_rows.size():
		if import_data.remove_first_row and i == 0:
			continue

		res = import_data.strings_to_resource(csv_rows[i])
		res.resource_path = ""
		insert_func.call_func(res, rows, sort_by, sort_reverse)
		resource_original_positions[res] = i
	
	editor_view.fill_property_data(rows[0])
	file.close()
	return rows
