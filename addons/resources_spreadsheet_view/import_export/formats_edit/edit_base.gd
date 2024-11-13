class_name ResourceTablesEditFormat
extends RefCounted

var editor_view : Control

## Override to define reading behaviour.
func get_value(entry, key : String):
	pass

## Override to define writing behaviour. This is NOT supposed to save - use `save_entries`.
func set_value(entry, key : String, value, index : int):
	pass

## Override to define how the data gets saved.
func save_entries(all_entries : Array, indices : Array):
	pass

## Override to allow editing rows from the Inspector.
func create_resource(entry) -> Resource:
	return Resource.new()

## Override to define duplication behaviour. `name_input` should be a suffix if multiple entries, and full name if one.
func duplicate_rows(rows : Array, name_input : String):
	pass

## Override to define removal behaviour.
func delete_rows(rows : Array):
	pass

## Override with `return true` if `resource_path` is defined and the Rename butoon should show.
func has_row_names():
	return false

## Override to define import behaviour. Must return the `rows` value for the editor view.
func import_from_path(folderpath : String, insert_func : Callable, sort_by : String, sort_reverse : bool = false) -> Array:
	return []
