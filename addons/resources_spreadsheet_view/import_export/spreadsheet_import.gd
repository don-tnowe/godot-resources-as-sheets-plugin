@tool
class_name ResourceTablesImport
extends Resource

enum PropType {
	BOOL,
	INT,
	FLOAT,
	STRING,
	COLOR,
	OBJECT,
	ENUM,
	MAX,
}

enum NameCasing {
	ALL_LOWER,
	CAPS_WORD_EXCEPT_FIRST,
	CAPS_WORD,
	ALL_CAPS,
}

const SUFFIX := "_spreadsheet_import.tres"
const TYPE_MAP := {
	TYPE_STRING : PropType.STRING,
	TYPE_FLOAT : PropType.FLOAT,
	TYPE_BOOL : PropType.BOOL,
	TYPE_INT : PropType.INT,
	TYPE_OBJECT : PropType.OBJECT,
	TYPE_COLOR : PropType.COLOR,
}

@export var prop_types : Array
@export var prop_names : Array

@export var edited_path := "res://"
@export var prop_used_as_filename := ""
@export var script_classname := ""
@export var remove_first_row := true

@export var new_script : GDScript
@export var view_script : Script = ResourceTablesEditFormatCsv
@export var delimeter := ";"
@export var enum_format : Array = [NameCasing.CAPS_WORD, " ", "Yes", "No"]

@export var uniques : Dictionary


func initialize(path):
	edited_path = path
	prop_types = []
	prop_names = []


func save():
	resource_path = edited_path.get_basename() + SUFFIX
	ResourceSaver.save.call_deferred(self)


func string_to_property(string : String, col_index : int):
	match prop_types[col_index]:
		PropType.STRING:
			return string

		PropType.BOOL:
			string = string.to_lower()
			if string == enum_format[2].to_lower(): return true
			if string == enum_format[3].to_lower(): return false
			return !string in ["no", "disabled", "-", "false", "absent", "wrong", "off", "0", ""]

		PropType.FLOAT:
			return string.to_float()

		PropType.INT:
			return string.to_int()

		PropType.COLOR:
			return Color(string)

		PropType.OBJECT:
			return load(string)

		PropType.ENUM:
			if string == "":
				return int(uniques[col_index]["N_A"])

			else:
				return int(uniques[col_index][string.capitalize().replace(" ", "_").to_upper()])


func property_to_string(value, col_index : int) -> String:
	if value == null: return ""
	if col_index == 0:
		if prop_names[col_index] == "resource_path":
			return value.get_file().get_basename()
	
	if prop_types[col_index] is PackedStringArray:
		return prop_types[col_index][value].capitalize()

	match prop_types[col_index]:
		PropType.STRING:
			return str(value)

		PropType.BOOL:
			return enum_format[2] if value else enum_format[3]

		PropType.FLOAT, PropType.INT:
			return str(value)

		PropType.COLOR:
			return value.to_html()

		PropType.OBJECT:
			return value.resource_path

		PropType.ENUM:
			var dict = uniques[col_index]
			for k in dict:
				if dict[k] == value:
					return change_name_to_format(k, enum_format[0], enum_format[1])
		
	return str(value)


func create_property_line_for_prop(col_index : int) -> String:
	var result : String = "@export var " + prop_names[col_index] + " :"
	match prop_types[col_index]:
		PropType.STRING:
			return result + "= \"\"\r\n"

		PropType.BOOL:
			return result + "= false\r\n"

		PropType.FLOAT:
			return result + "= 0.0\r\n"

		PropType.INT:
			return result + "= 0\r\n"

		PropType.COLOR:
			return result + "= Color.WHITE\r\n"

		PropType.OBJECT:
			return result + " Resource\r\n"

		PropType.ENUM:
			return result + " %s\r\n" % _escape_forbidden_enum_names(prop_names[col_index].capitalize().replace(" ", ""))
			# return result.replace(
			# 	"@export var",
			# 	"@export_enum(" + _escape_forbidden_enum_names(
			# 			prop_names[col_index].capitalize()\
			# 				.replace(" ", "")
			# 		) + ") var"
			# ) + "= 0\r\n"

	return ""


func _escape_forbidden_enum_names(string : String) -> String:
	if ClassDB.class_exists(string):
		return string + "_"
	
	# Not in ClassDB, but are engine types and can be property names
	if string in [
		"Color", "String", "Plane", "Projection",
		"Basis", "Transform", "Variant",
	]:
		return string + "_"

	return string


func create_enum_for_prop(col_index) -> String:
	var result := (
		"enum "
		+ _escape_forbidden_enum_names(
			prop_names[col_index].capitalize().replace(" ", "")
		) + " {\r\n"
	)
	for k in uniques[col_index]:
		result += (
			"\t"
			+ k  # Enum Entry
			+ " = "
			+ str(uniques[col_index][k])  # Value
			+ ",\r\n"
		)
	result += "\tMAX,\r\n}\r\n\r\n"
	return result


func generate_script(entries, has_classname = true) -> GDScript:
	var source := ""
#	if has_classname and script_classname != "":
#		source = "class_name " + script_classname + " \r\nextends Resource\r\n\r\n"
#
#	else:
	source = "extends Resource\r\n\r\n"
	
	# Enums
	uniques = get_uniques(entries)
	for i in prop_types.size():
		if prop_types[i] == PropType.ENUM:
			source += create_enum_for_prop(i)
	
	# Properties
	for i in prop_names.size():
		if (prop_names[i] != "resource_path") and (prop_names[i] != "resource_name"):
			source += create_property_line_for_prop(i)
	
	var created_script : GDScript = GDScript.new()
	created_script.source_code = source
	created_script.reload()
	return created_script


func strings_to_resource(strings : Array):
	var new_res := new_script.new()
	for j in min(prop_names.size(), strings.size()):
		new_res.set(prop_names[j], string_to_property(strings[j], j))
	
	if prop_used_as_filename != "":
		new_res.resource_path = edited_path.get_basename() + "/" + new_res.get(prop_used_as_filename) + ".tres"
	
	return new_res


func resource_to_strings(res : Resource):
	var strings := []
	strings.resize(prop_names.size())
	for i in prop_names.size():
		strings[i] = property_to_string(res.get(prop_names[i]), i)
	
	return PackedStringArray(strings)


func get_uniques(entries : Array) -> Dictionary:
	var result := {}
	for i in prop_types.size():
		if prop_types[i] == PropType.ENUM:
			var cur_value := ""
			result[i] = {}
			for j in entries.size():
				if j == 0 and remove_first_row: continue

				cur_value = entries[j][i].capitalize().to_upper().replace(" ", "_")
				if cur_value == "":
					cur_value = "N_A"
				
				if !result[i].has(cur_value):
					result[i][cur_value] = result[i].size()

	return result


static func change_name_to_format(name : String, case : int, delim : String):
	var string := name.capitalize().replace(" ", delim)
	if case == NameCasing.ALL_LOWER:
		return string.to_lower()

	if case == NameCasing.CAPS_WORD_EXCEPT_FIRST:
		return string[0].to_lower() + string.substr(1)

	if case == NameCasing.CAPS_WORD:
		return string

	if case == NameCasing.ALL_CAPS:
		return string.to_upper()


static func get_resource_property_types(res : Resource, properties : Array) -> Array:
	var result := []
	result.resize(properties.size())
	result.fill(PropType.STRING)
	var cur_type := 0
	for x in res.get_property_list():
		var found := properties.find(x["name"])
		if found == -1: continue
		if x["usage"] & PROPERTY_USAGE_EDITOR != 0:
			if x["hint"] == PROPERTY_HINT_ENUM:
				var enum_values : PackedStringArray = x["hint_string"].split(",")
				for i in enum_values.size():
					var index_found : int = enum_values[i].find(":")
					if index_found == -1: continue
					enum_values[i] = enum_values[i].left(index_found)

				result[found] = enum_values

			else:
				result[found] = TYPE_MAP.get(x["type"], PropType.STRING)
	
	return result
