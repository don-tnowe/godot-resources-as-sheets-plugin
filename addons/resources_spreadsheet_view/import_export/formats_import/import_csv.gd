class_name ResourceTablesImportFormatCsv
extends RefCounted


static func can_edit_path(path : String):
	return path.ends_with(".csv")


static func get_properties(entries, import_data):
	return Array(entries[0])


static func import_as_arrays(import_data) -> Array:
	var file := FileAccess.open(import_data.edited_path, FileAccess.READ)

	import_data.delimeter = ";"
	var text_lines : Array[PackedStringArray] = [file.get_line().split(import_data.delimeter)]
	var space_after_delimeter := false
	var line := text_lines[0]
	if line.size() == 0:
		return []

	if line.size() == 1:
		import_data.delimeter = ","
		line = line[0].split(import_data.delimeter)
		text_lines[0] = line
		if line.size() <= 1:
			return []

	if line[1].begins_with(" "):
		for i in line.size():
			line[i] = line[i].trim_prefix(" ")
		
		text_lines[0] = line
		space_after_delimeter = true
		import_data.delimeter += " "

	while !file.eof_reached():
		line = file.get_csv_line(import_data.delimeter[0])
		if space_after_delimeter:
			for i in line.size():
				line[i] = line[i].trim_prefix(" ")

		if line.size() == text_lines[0].size():
			text_lines.append(line)

		elif line.size() != 1:
			line.resize(text_lines[0].size())
			text_lines.append(line)

	var entries := []
	entries.resize(text_lines.size())

	for i in entries.size():
		entries[i] = text_lines[i]

	import_data.prop_names = entries[0]
	return entries