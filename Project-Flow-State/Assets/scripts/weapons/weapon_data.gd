##
## Weapon Data Script
## This is a simple data class that allows for weapons to have ammo and be unlocked dynamically
##
##

class_name WeaponData extends Resource

@export var weapon: Weapon
@export var unlocked: bool = false
@export var ammo: int = 0
@export var max_ammo: int = 0
