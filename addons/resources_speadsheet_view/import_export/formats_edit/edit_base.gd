class_name SpreadsheetEditFormat
extends Reference

var editor_view : Control

## Override to define reading behaviour.
func get_value(entry, key : String):
	pass

## Override to define writing behaviour. This is NOT supposed to save - use `save_entry`.
func set_value(entry, key : String, value):
	pass

## Override to define how the data gets saved.
func save_entry(all_entries : Array, index : int):
	pass

## Override to allow editing rows from the Inspector.
func create_resource(entry) -> Resource:
	return Resource.new()

## Override to define 
func import_from_path(folderpath : String, insert_func : FuncRef, sort_by : String, sort_reverse : bool = false) -> Array:
	return []
