##
## Ammo Pickup Script
## This is the parent class for all ammo pickups regardless of ammo type
##
##

@tool

class_name AmmoPickup extends BasePickup

@export var ammo_amount: int = 10

func _func_godot_apply_properties(entity_properties: Dictionary) -> void:
	ammo_amount = entity_properties["ammo_amount"] as int

func can_pickup(player: PlayerController) -> bool:
	#Check if weapon exists
	if not Managers.weapon_manager.current_slot:
		return false
	
	var weapon_data = Managers.weapon_manager.weapons[Managers.weapon_manager.current_slot]
	
	# Can only pickup if ammo is not full
	return weapon_data.ammo < weapon_data.max_ammo

func apply_pickup(player: PlayerController) -> void:
	var weapon_data = Managers.weapon_manager.weapons[Managers.weapon_manager.current_slot]
	
	# Calculate how much ammo to add (Don't exceed max)
	var space_available = weapon_data.max_ammo - weapon_data.ammo
	var ammo_to_add = min(ammo_amount, space_available)
	
	# Add ammo
	weapon_data.ammo += ammo_to_add
	
	print ("picked up ", ammo_to_add, " ammo for ", weapon_data.weapon.weapon_name)
