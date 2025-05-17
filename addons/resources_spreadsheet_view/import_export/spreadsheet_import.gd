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
	COLLECTION,
	MAX,
}

enum NameCasing {
	ALL_LOWER,
	CAPS_WORD_EXCEPT_FIRST,
	CAPS_WORD,
	ALL_CAPS,
}

const SUFFIX := "_table_import.tres"
const TYPE_MAP := {
	TYPE_STRING : PropType.STRING,
	TYPE_FLOAT : PropType.FLOAT,
	TYPE_BOOL : PropType.BOOL,
	TYPE_INT : PropType.INT,
	TYPE_OBJECT : PropType.OBJECT,
	TYPE_COLOR : PropType.COLOR,
	TYPE_ARRAY : PropType.COLLECTION,
	TYPE_DICTIONARY : PropType.COLLECTION,
}

@export var prop_types : Array
@export var prop_names : Array

@export var edited_path := "res://"
@export var prop_used_as_filename := ""
@export var script_classname := ""
@export var remove_first_row := true

@export var new_script : Script
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
			return null if string == "" else load(string)

		PropType.ENUM:
			if string == "":
				return int(uniques[col_index]["N_A"])

			else:
				if !uniques.has(col_index):
					return -1

				return int(uniques[col_index][string.capitalize().replace(" ", "_").to_upper()])
				# if string.is_valid_int():
				# 	return int(uniques[col_index][string.capitalize().replace(" ", "_").to_upper()])
				# else:
				# 	# If the enum is a string, we actually just want the key not the value
				# 	var enum_keys : Dictionary = uniques[col_index]
				# 	return int(enum_keys.find_key(string))

		PropType.COLLECTION:
			var result = str_to_var(string)
			if result is Array:
				for i in result.size():
					if result[i] is String && result[i].begins_with("res://"):
						result[i] = load(result[i])

			if result is Dictionary:
				for k in result:
					if result[k] is String && result[k].begins_with("res://"):
						result[k] = load(result[k])

			if result == null:
				result = []

			return result


func property_to_string(value, col_index : int) -> String:
	if value == null: return ""
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

		PropType.COLLECTION:
			if value is Array:
				var new_value := []
				new_value.resize(value.size())
				for i in value.size():
					new_value[i] = value[i]
					if value[i] is Resource:
						new_value[i] = value[i].resource_path

				value = new_value

			if value is Dictionary:
				var new_value := {}
				for k in value:
					new_value[k] = value[k]
					if value[k] is Resource:
						new_value[k] = value[k].resource_path

					if k is Resource:
						new_value[k.resource_path] = new_value[k]

				value = new_value

			return str(value)

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

		PropType.COLLECTION:
			return result + "= []\r\n"

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


func load_property_names_from_textfile(path : String, loaded_entries : Array):
	prop_types.resize(prop_names.size())
	prop_types.fill(4)
	var enums_exist := false
	for i in prop_names.size():
		prop_names[i] = loaded_entries[0][i]\
			.replace("\"", "")\
			.replace(" ", "_")\
			.replace("-", "_")\
			.replace(".", "_")\
			.replace(",", "_")\
			.replace("\t", "_")\
			.replace("/", "_")\
			.replace("\\", "_")\
			.to_lower()

		var value = loaded_entries[1][i]
		var value_cast = str_to_var(value)
		# Don't guess Ints automatically - further rows might have floats
		if value_cast is Array or value_cast is Dictionary:
			prop_types[i] = ResourceTablesImport.PropType.COLLECTION
		elif value.is_valid_float():
			prop_types[i] = ResourceTablesImport.PropType.FLOAT
		elif value.begins_with("res://") && prop_names[i] != "resource_path":
			prop_types[i] = ResourceTablesImport.PropType.OBJECT
		elif value.length() == 6 or value.length() == 8 or (value.length() > 0 and value[0] == "#"):
			prop_types[i] = ResourceTablesImport.PropType.COLOR
		else:
			prop_types[i] = ResourceTablesImport.PropType.STRING
			enums_exist = true


func load_external_script(script_res : Script):
	new_script = script_res
	var result := {}
	for x in script_res.get_script_property_list():
		
		if x.hint != PROPERTY_HINT_ENUM or x.type != TYPE_INT:
			continue
		
		var cur_value := ""
		var result_for_prop := {}
		result[prop_names.find(x.name)] = result_for_prop
		var hint_arr : Array = x.hint_string.split(",")
		for current_hint in hint_arr.size():
			var colon_found : int = hint_arr[current_hint].rfind(":")
			cur_value = hint_arr[current_hint]
			if cur_value == "":
				cur_value = "N_A"

			if colon_found != -1:
				var value_split := cur_value.split(":")
				result_for_prop[value_split[1].to_upper()] = value_split[0]

			else:
				result_for_prop[cur_value.to_upper()] = result_for_prop.size()


func strings_to_resource(strings : Array, destination_path : String) -> Resource:
	if destination_path == "":
		destination_path = edited_path.get_base_dir().path_join("import/")
		DirAccess.make_dir_recursive_absolute(destination_path)
	
	# If a full path is provided this catches that case
	var new_path : String = strings[prop_names.find(prop_used_as_filename)]
	
	if !FileAccess.file_exists(new_path):
		new_path = destination_path.path_join(new_path).trim_suffix(".tres") + ".tres"
	
	if !FileAccess.file_exists(new_path):
		new_path = (strings[prop_names.find(prop_used_as_filename)]
			.trim_prefix(destination_path)
			.trim_suffix(".tres") + ".tres"
		)
		if !new_path.begins_with("res://"):
			new_path = destination_path.path_join(new_path)

		DirAccess.make_dir_recursive_absolute(new_path.get_base_dir())

	var new_res : Resource
	if FileAccess.file_exists(new_path):
		new_res = load(new_path)

	else:
		new_res = new_script.new()
		new_res.resource_path = new_path

	for i in mini(prop_names.size(), strings.size()):
		var property_value = string_to_property(strings[i], i)
		# This is awful, but the workaround for typed casting
		# 	https://github.com/godotengine/godot/issues/72620
		if property_value is Array or property_value is Dictionary:
			var property_value_as_typed = new_res.get(prop_names[i])
			property_value_as_typed.assign(property_value)
			new_res.set(prop_names[i], property_value_as_typed)

		else:
			new_res.set(prop_names[i], property_value)

	if prop_used_as_filename != "":
		new_res.resource_path = new_path

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
		if prop_types[i] is PropType and prop_types[i] == PropType.ENUM:
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


static func get_resource_property_types(res : Resource, properties : Array, uniques : Dictionary) -> Array:
	var result : Array[PropType] = []
	result.resize(properties.size())
	result.fill(PropType.STRING)
	var cur_type := 0
	for x in res.get_property_list():
		var poroperty_index := properties.find(x[&"name"])
		if poroperty_index == -1: continue
		if x[&"usage"] & PROPERTY_USAGE_EDITOR != 0:
			if x[&"hint"] == PROPERTY_HINT_ENUM:
				var enum_values : PackedStringArray = x[&"hint_string"].split(",")
				var enum_value_dict := {}
				var max_enum_value := 0
				for i in enum_values.size():
					var index_found : int = enum_values[i].find(":")
					if index_found == -1:
						enum_value_dict[enum_values[i].to_upper()] = max_enum_value
						max_enum_value += 1
						continue

					var k = enum_values[i].left(index_found).to_upper()
					var v = enum_values[i].right(index_found + 1).to_int()
					enum_value_dict[k] = v

				uniques[poroperty_index] = enum_value_dict
				result[poroperty_index] = PropType.ENUM

			else:
				result[poroperty_index] = TYPE_MAP.get(x[&"type"], PropType.STRING)
	
	return result
