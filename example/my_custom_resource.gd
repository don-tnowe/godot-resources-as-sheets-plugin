tool
class_name DynamicWheelItem
extends Resource

export var color1 := Color.white
export var max_duplicates := 0
export var tags := "tag_1 tag_2 tag_3"
export var color2 := Color.white
export(String) var tag_delimeter = " "
export var base_weight := 10.0
export var is_notable := false
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
