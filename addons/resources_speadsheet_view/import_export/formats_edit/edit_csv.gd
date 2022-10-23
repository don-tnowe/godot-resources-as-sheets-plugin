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
		if import_data.remove_first_row:
			var names = []
			names.resize(import_data.prop_names.size())
			for i in names.size():
				names[i] = TextEditingUtils.string_snake_to_naming_case(import_data.prop_names[i])
				if i != 0 and space_after_delimeter:
					names[i] = " " + names[i]
			
			file.store_csv_line(names, import_data.delimeter[0])

		for x in csv_rows:
			if space_after_delimeter:
				for i in x.size():
					if i == 0: continue
					x[i] = " " + x[i]

			file.store_csv_line(x, import_data.delimeter[0])
		
		file.close()
		if repeat:
			timer = editor_view.get_tree().create_timer(5.0)
			timer.connect("timeout", self, "save_entries", [all_entries, indices, false])


func create_resource(entry) -> Resource:
	return entry


func import_from_path(path : String, insert_func : FuncRef, sort_by : String, sort_reverse : bool = false) -> Array:
	import_data = load(path)
	var file = File.new()
	file.open(import_data.edited_path, File.READ)

	var line
	var first = true
	var space_after_delimeter = import_data.delimeter.ends_with(" ")
	csv_rows = []
	while !file.eof_reached():
		line = file.get_csv_line(import_data.delimeter[0])
		if space_after_delimeter:
			for i in line.size():
				line[i] = line[i].trim_prefix(" ")

		if first and import_data.remove_first_row:
			line = " "
			first = false
			continue
		
		if csv_rows.size() == 0:
			csv_rows.append(line)

		elif line.size() != 1:
			if line.size() != csv_rows[0].size():
				line.resize(csv_rows[0].size())
				
			csv_rows.append(line)

	var rows := []
	var res : Resource
	resource_original_positions.clear()
	for i in csv_rows.size():
		res = import_data.strings_to_resource(csv_rows[i])
		insert_func.call_func(res, rows, sort_by, sort_reverse)
		resource_original_positions[res] = i
	
	editor_view.fill_property_data(rows[0])
	return rows
