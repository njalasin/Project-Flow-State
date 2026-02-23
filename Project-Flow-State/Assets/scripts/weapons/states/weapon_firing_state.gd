extends WeaponState


func _on_firing_state_entered() -> void:
	if not weapon_controller:
		return
	
	# Since we're in firing state, fire on state entry
	weapon_controller.fire_weapon()
	
func _on_firing_state_physics_processing(delta: float) -> void:
	if not weapon_controller:
		return
		
	# Check if ammo is empty, send to empty state if so
	if not weapon_controller.has_ammo():
		weapon_controller.weapon_state_chart.send_event("onEmpty")
		return
	
	# Check fire mode
	if weapon_controller.current_weapon.is_automatic:
		# Automatic: Keep firing if trigger is held
		if Input.is_action_pressed("attack"):
			if weapon_controller.can_fire():
				weapon_controller.fire_weapon()
		else:
			# Trigger released return to idle
			weapon_controller.weapon_state_chart.send_event("onIdle")
	else:
		# Semi-Auto: fire once then return to idle
		weapon_controller.weapon_state_chart.send_event("onIdle")
	
	# Reload, even if currently shooting
	if Input.is_action_just_pressed("reload"):
		Managers.weapon_manager.reload(Managers.weapon_manager.current_slot)
		print("Reloaded: ", Managers.weapon_manager.max_ammo, " bullets")
		weapon_controller.weapon_state_chart.send_event("onIdle")
