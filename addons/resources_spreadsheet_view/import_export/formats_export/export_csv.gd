class_name ResourceTablesExportFormatCsv
extends RefCounted


static func can_edit_path(path : String):
	return path.ends_with(".csv")


static func export_to_file(entries_array : Array, column_names : Array, into_path : String, import_data):
	var file = FileAccess.open(into_path, FileAccess.WRITE)

	var line = PackedStringArray()
	var space_after_delimeter = import_data.delimeter.ends_with(" ")
	import_data.prop_names = column_names
	import_data.prop_types = import_data.get_resource_property_types(entries_array[0], column_names)
	import_data.resource_path = ""
	line.resize(column_names.size())
	if import_data.remove_first_row:
		for j in column_names.size():
			line[j] = column_names[j]
			if space_after_delimeter and j != 0:
				line[j] = " " + line[j]
		
		file.store_csv_line(line, import_data.delimeter[0])

	for i in entries_array.size():
		for j in column_names.size():
			line[j] = import_data.property_to_string((entries_array[i].get(column_names[j])), j)
			if space_after_delimeter and j != 0:
				line[j] = " " + line[j]

		file.store_csv_line(line, import_data.delimeter[0])
