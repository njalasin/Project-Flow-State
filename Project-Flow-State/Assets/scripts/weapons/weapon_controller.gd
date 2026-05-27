##
## Weapon Controller Script
## This is where weapon firing and ammo consumption logic is processed
##
##

class_name WeaponController extends Node

@export var camera : Camera3D
@export var weapon_model_parent : Node3D
@export var weapon_state_chart : StateChart

var current_weapon_model : Node3D
var max_ammo : int
var can_fire_next : bool = true
var fire_rate_timer : float = 0.0
var current_weapon : Weapon

func _ready() -> void:
	if current_weapon:
		spawn_weapon_model()

func _process(delta: float) -> void:
	if fire_rate_timer > 0:
		fire_rate_timer -= delta
		if fire_rate_timer <= 0:
			can_fire_next = true

func spawn_weapon_model() -> void:
	if current_weapon_model:
		current_weapon_model.queue_free()

	if current_weapon.weapon_model:
		current_weapon_model = current_weapon.weapon_model.instantiate()
		weapon_model_parent.add_child(current_weapon_model)
		current_weapon_model.position = current_weapon.weapon_position

func can_fire() -> bool:
	var weapon_data = Managers.weapon_manager.weapons[Managers.weapon_manager.current_slot]
	return weapon_data.ammo > 0 and can_fire_next

func fire_weapon() -> void:
	if can_fire():
		Managers.weapon_manager.use_ammo(Managers.weapon_manager.current_slot)
		print("Fired weapon. Ammo: ", Managers.weapon_manager.get_current_ammo())
		
		# Start fire rate cooldown
		can_fire_next = false
		fire_rate_timer = 1.0 / current_weapon.fire_rate
		
		if current_weapon.is_hitscan:
			_perform_hitscan()
		else:
			_spawn_projectile()

func _perform_hitscan() -> void:
	if not camera:
		print("No camera assigned!")
		return
	var space_state = camera.get_world_3d().direct_space_state
	var from = camera.global_position
	var accuracy_spread = (100 - current_weapon.accuracy) / 1000.0
	
	for i in current_weapon.pellet_count:
		var forward = -camera.global_transform.basis.z
		# Add accuracy randomness
		var accuracy_x = randf_range(-accuracy_spread, accuracy_spread)
		var accuracy_y = randf_range(-accuracy_spread, accuracy_spread)
		var direction = forward + Vector3(accuracy_x, accuracy_y, 0) * camera.global_transform.basis
		if current_weapon.pellet_count > 1:
			var spread_x = randf_range(-current_weapon.spread_angle, current_weapon.spread_angle)
			var spread_y = randf_range(-current_weapon.spread_angle, current_weapon.spread_angle)
			direction += Vector3(spread_x, spread_y, 0) * camera.global_transform.basis
		var to = from + direction * current_weapon.range
		var query = PhysicsRayQueryParameters3D.create(from,to)
		var result = space_state.intersect_ray(query)
	
		if result:
			print("Hit: ", result.collider.name, " at ", result.position)
			_spawn_impact_marker(result.position)
			
			_apply_damage_to_target(result.collider)

func _spawn_impact_marker(position: Vector3) -> void:
	var marker = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.1,0.1, 0.1)
	marker.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	marker.set_surface_override_material(0, material)
	
	get_tree().current_scene.add_child(marker)
	marker.global_position = position
	
	get_tree().create_timer(2.0).timeout.connect(marker.queue_free)

func _spawn_projectile() -> void:
	if not current_weapon.projectile_scene:
		print("No projectile assigned!")
		return
	if not camera:
		print("No camera assigned!")
	
	# Spawn the projectile
	var projectile = current_weapon.projectile_scene.instantiate() as Projectile
	get_tree().current_scene.add_child(projectile)
	
	# Position at firing point
	projectile.global_position = weapon_model_parent.global_position
	
	# Calculate accuracy spread
	var accuracy_spread = (100 - current_weapon.accuracy) / 1000.0
	# Calculate direction and velocity
	var forward = -camera.global_transform.basis.z
	
	var accuracy_x = randf_range(-accuracy_spread, accuracy_spread)
	var accuracy_y = randf_range(-accuracy_spread, accuracy_spread)
	var direction = forward + Vector3(accuracy_x, accuracy_y, 0) * camera.global_transform.basis
	
	var velocity = direction * current_weapon.projectile_speed
	projectile.look_at(projectile.global_position + direction, Vector3.UP)
	# Setup the projectile
	projectile.setup(velocity, current_weapon.damage)

func switch_weapon(weapon_data: WeaponData) -> void:
	current_weapon = weapon_data.weapon
	
	if current_weapon_model:
		current_weapon_model.queue_free()
		
	spawn_weapon_model()
	
	weapon_state_chart.send_event("onIdle")

func has_ammo() -> bool:
	var weapon_data = Managers.weapon_manager.weapons[Managers.weapon_manager.current_slot]
	return weapon_data.ammo > 0

func _apply_damage_to_target(target: Node3D) -> void:
	# Check if target has a Health Component
	var health_component = target.get_node_or_null("HealthComponent")
	
	if health_component and health_component.has_method("take_damage"):
		health_component.take_damage(current_weapon.damage, owner)
