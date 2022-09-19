tool
class_name DynamicWheelItem
extends Resource

export var max_duplicates := 0
export var tags := "tag_1 tag_2 tag_3"
export var requires_one_of_tags := ""
export(String) var tag_delimeter = " "
export var base_weight := 10.0
export(String, MULTILINE) var multiplier_per_tag := ""
export(String, MULTILINE) var multiplier_if_tag_present := ""
export(String, MULTILINE) var multiplier_if_tag_not_present := ""
export(String, MULTILINE) var max_tags_present := ""
export(String) var list_item_delimeter = " "
export(String) var list_row_delimeter = ";"

var is_cached := false
var tag_array := []
var requires_one_of_tags_array := []
var multiplier_per_tag_dict := {}
var multiplier_if_tag_present_dict := {}
var multiplier_if_tag_not_present_dict := {}
var max_tags_present_dict := {}


func get_weight(owned_tags : Dictionary) -> float:
  if !is_cached:
    _cache_lists()

  for k in max_tags_present_dict:
    if owned_tags.get(k, 0) >= max_tags_present_dict[k]:
      return 0.0

  var result_weight := base_weight
  for k in multiplier_per_tag_dict:
    result_weight *= pow(multiplier_per_tag_dict[k], owned_tags.get(k, 0))

  for k in multiplier_if_tag_not_present_dict:
    if owned_tags.has(k):
      result_weight *= multiplier_if_tag_present_dict[k]
    
  for k in multiplier_if_tag_not_present_dict:
    if owned_tags.has(k):
      result_weight *= multiplier_if_tag_present_dict[k]

  return result_weight


func _cache_lists():
  tag_array = tags.split(tag_delimeter)
  requires_one_of_tags_array = requires_one_of_tags.split(tag_delimeter)

  multiplier_per_tag_dict.clear()
  multiplier_if_tag_present_dict.clear()
  multiplier_if_tag_not_present_dict.clear()
  max_tags_present_dict.clear()

  _cache_text_into_dictionary(multiplier_per_tag_dict, multiplier_per_tag)
  _cache_text_into_dictionary(multiplier_if_tag_present_dict, multiplier_if_tag_present)
  _cache_text_into_dictionary(multiplier_if_tag_not_present_dict, multiplier_if_tag_not_present)
  _cache_text_into_dictionary(max_tags_present_dict, max_tags_present)

  is_cached = true


func _cache_text_into_dictionary(dict : Dictionary, list_string : String):
  for x in list_string.split(list_row_delimeter):
    dict[x.left(x.find(list_item_delimeter))] = float(x.right(x.rfind(list_item_delimeter) + list_item_delimeter.length()))

  print(dict)
