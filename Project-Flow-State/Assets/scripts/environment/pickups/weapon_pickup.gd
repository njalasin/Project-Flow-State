class_name WeaponPickup extends BasePickup

@export var slot: int
@export var weapon_resource: Weapon

func can_pickup(player: PlayerController) -> bool:
	var weapon_data = Managers.weapon_manager.weapons[slot]
	# Can pickup if: weapon locked OR ammo not full
	return not weapon_data.unlocked or weapon_data.ammo < weapon_data.max_ammo

func apply_pickup(player: PlayerController) -> void:
	var weapon_data = Managers.weapon_manager.weapons[slot]
	
	if weapon_data.unlocked:
		# Weapon already unlocked - refill ammo instead
		weapon_data.ammo = weapon_data.max_ammo
		print("Ammo refilled: ", weapon_resource.weapon_name)
	else:
		# Unlock weapon and switch to it
		Managers.weapon_manager.unlock_weapon(slot, weapon_resource)
		Managers.weapon_manager.switch_to_slot(slot)
		print("Unlocked: ", weapon_resource.weapon_name)
