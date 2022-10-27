class_name Upgrades 
extends Resource

enum Type {
	PASSIVE = 0,
	MASTERY = 1,
	WEAPON = 2,
	MAX,
}

export var color1 := ""
export var max_duplicates := 0.0
export var tags := ""
export(Type) var type := 0
export var attributes := ""
export var icon : Resource
export var custom_scene := ""
export var color2 := ""
export var base_weight := 0.0
export var is_notable := false
export var multiplier_per_tag := ""
export var multiplier_if_tag_present := ""
export var multiplier_if_tag_not_present := ""
export var max_tags_present := ""
export var list_item_delimeter := ""
export var list_row_delimeter := ""
