@tool
class_name UpgradeData
extends Resource

enum Attributes {
  Strength = 0,
  Magic,
  Endurance,
  Agility,
  Luck,
  Mastery = 128,
}

@export var color1 := Color.WHITE
@export var max_duplicates := 0
@export var tags : Array[String]
@export_enum("Weapon", "Passive", "Mastery") var type := 0
@export var attributes : Array[Attributes]
@export var icon : Texture
@export var custom_scene : PackedScene
@export var prerequisites : Array[UpgradeData]
@export var color2 := Color.WHITE
@export var base_weight := 10.0
@export var is_notable := false
@export_multiline var multiplier_per_tag := ""
@export_multiline var multiplier_if_tag_present := ""
@export_multiline var multiplier_if_tag_not_present := ""
@export_multiline var max_tags_present := ""
@export var list_item_delimeter := " "
@export var list_row_delimeter := ";"
