@tool
extends "res://example/Random Upgrades/upgrade_data.gd"

@export var weapon_damage := 0.0
@export var weapon_cooldown := 0.0
@export var weapon_dps := 0.0:
    set(v):
        weapon_damage = v * weapon_cooldown
    get:
        return weapon_damage / weapon_cooldown if weapon_cooldown != 0.0 else 0.0


func _validate_property(property: Dictionary) -> void:
    if property.name == &"weapon_dps":
        # Show in inspector, but don't save into resource file.
        property.usage = PROPERTY_USAGE_EDITOR
