extends WeaponState

func _on_empty_state_entered() -> void:
	print("Weapon empty")
	
func _on_empty_state_processing(delta: float) -> void:
	
	# Reload while weapon is empty
	if Input.is_action_just_pressed("reload"):
		Managers.weapon_manager.reload(Managers.weapon_manager.current_slot)
		print("Reloaded: ", Managers.weapon_manager.max_ammo, " bullets")
		weapon_controller.weapon_state_chart.send_event("onIdle")
	pass
