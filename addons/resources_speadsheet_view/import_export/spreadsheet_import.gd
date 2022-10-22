tool
class_name SpreadsheetImport
extends Resource

const SUFFIX := "_spreadsheet_import.tres"

enum PropType {
	BOOL,
	INT,
	REAL,
	STRING,
	VECTOR2,
	RECT2,
	VECTOR3,
	COLOR,
	ARRAY,
	OBJECT,
	ENUM,
	MAX,
}

export var prop_types : Array
export var prop_names : Array

export var edited_path := "res://"
export var prop_used_as_filename := ""
export var script_classname := ""
export var remove_first_row := true

export var new_script : GDScript
export var view_script : Script = SpreadsheetEditFormatCsv
export var delimeter := ";"

export var uniques : Dictionary


func initialize(path):
  resource_path = path.get_basename() + SUFFIX
  edited_path = path
  prop_types = []
  prop_names = []


func save():
	ResourceSaver.call_deferred("save", edited_path.get_basename() + SUFFIX, self)


func string_to_property(string : String, col_index : int):
  match prop_types[col_index]:
    PropType.STRING:
      return string

    PropType.BOOL:
      string = string.to_lower()
      return !string in ["no", "disabled", "-", "false", "absent", "wrong", ""]

    PropType.REAL:
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
        return int(uniques[col_index][string.to_upper().replace(" ", "_")])


func property_to_string(value, col_index : int):
  match prop_types[col_index]:
    PropType.STRING:
      return value

    PropType.BOOL:
      return str(value)  # TODO: make this actually persist

    PropType.REAL, PropType.INT:
      return str(value)

    PropType.COLOR:
      return value.to_html()

    PropType.OBJECT:
      return value.resource_path

    PropType.ENUM:
      var dict = uniques[col_index]
      for k in dict:
        if dict[k] == value:
          return TextEditingUtils.string_snake_to_naming_case(k)


func create_property_line_for_prop(col_index : int):
  var result = "export var " + prop_names[col_index] + " :"
  match prop_types[col_index]:
    PropType.STRING:
      return result + "= \"\"\n"

    PropType.BOOL:
      return result + "= false\n"

    PropType.REAL:
      return result + "= 0.0\n"

    PropType.INT:
      return result + "= 0\n"

    PropType.COLOR:
      return result + "= Color.white\n"

    PropType.OBJECT:
      return result + " Resource\n"

    PropType.ENUM:
      return result.replace(
        "export var",
        "export("
          + TextEditingUtils.string_snake_to_naming_case(
            prop_names[col_index]
          ).replace(" ", "")
          + ") var"
      ) + "= 0\n"


func create_enum_for_prop(col_index):
  var result := (
    "enum "
    + TextEditingUtils.string_snake_to_naming_case(prop_names[col_index]).replace(" ", "")
    + " {\n"
  )
  for k in uniques[col_index]:
    result += (
      "\t"
      + k  # Enum Entry
      + " = "
      + str(uniques[col_index][k])  # Value
      + ",\n"
    )
  result += "\tMAX,\n}\n\n"
  return result


func strings_to_resource(strings : Array):
  var new_res = new_script.new()
  for j in prop_names.size():
    new_res.set(prop_names[j], string_to_property(strings[j], j))
  
  if prop_used_as_filename != "":
    new_res.resource_path = edited_path.get_basename() + "/" + new_res.get(prop_used_as_filename) + ".tres"
  
  return new_res


func resource_to_strings(res : Resource):
  var strings := []
  strings.resize(prop_names.size())
  for i in prop_names.size():
    strings[i] = property_to_string(res.get(prop_names[i]), i)
  
  return PoolStringArray(strings)
