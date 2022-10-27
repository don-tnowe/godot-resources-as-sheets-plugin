tool
extends Resource

enum Attributes {
  Strength,
  Magic,
  Endurance,
  Agility,
  Luck,
}

enum Type {
  Weapon,
  Passive,
  Mastery,
}

export var color1 := Color.white
export var max_duplicates := 0
export(Array, String) var tags : Array
export(Type) var type := 0
export(Array, Attributes) var attributes
export var icon : Texture
export var custom_scene : PackedScene
export var color2 := Color.white
export var base_weight := 10.0
export var is_notable := false
export(String, MULTILINE) var multiplier_per_tag := ""
export(String, MULTILINE) var multiplier_if_tag_present := ""
export(String, MULTILINE) var multiplier_if_tag_not_present := ""
export(String, MULTILINE) var max_tags_present := ""
export var list_item_delimeter := " "
export var list_row_delimeter := ";"
