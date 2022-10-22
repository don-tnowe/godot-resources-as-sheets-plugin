class_name SpreadsheetImport
extends Resource

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

var prop_types := []
var prop_names := []

var path := "res://"
var prop_used_as_filename := "name"
var script_classname := ""
var remove_first_row := true

var new_script : GDScript


func save():
	resource_path = path.get_basename() + "_spreadsheet_import.tres"
	ResourceSaver.save(resource_path, self)


func string_to_property(string : String, col_index : int, uniques : Dictionary):
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


func create_enum_for_prop(col_index, uniques):
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


func strings_to_resource(strings : Array, uniques : Dictionary):
  var new_res = new_script.new()
  for j in prop_names.size():
    new_res.set(prop_names[j], string_to_property(strings[j], j, uniques))
  
  new_res.resource_path = path.get_basename() + "/" + new_res.get(prop_used_as_filename) + ".tres"
  return new_res
