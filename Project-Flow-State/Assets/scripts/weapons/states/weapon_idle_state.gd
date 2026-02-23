extends WeaponState

# Called when the node enters the scene tree for the first time.
func _on_idle_state_processing(delta: float) -> void:
	if not weapon_controller:
		return
	
	# Check form fire input
	if Input.is_action_pressed("attack") and weapon_controller.can_fire():
		weapon_controller.weapon_state_chart.send_event("onFiring")
	
	# Check if ammo is empty
	if not weapon_controller.has_ammo():
		weapon_controller.weapon_state_chart.send_event("onEmpty")
	
	# Reload while weapon still has ammo remaining
	if Input.is_action_just_pressed("reload"):
		Managers.weapon_manager.reload(Managers.weapon_manager.current_slot)
		print("Reloaded: ", Managers.weapon_manager.max_ammo, " bullets")
		weapon_controller.weapon_state_chart.send_event("onIdle")
