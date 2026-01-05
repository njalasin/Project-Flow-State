class_name PlayerController extends CharacterBody3D

# Exported variables
@export var debug : bool = false
@export_category("References")
@export var camera : CameraController
@export var state_chart : StateChart
@export var standing_collision : CollisionShape3D
@export var crouching_collision : CollisionShape3D
@export var crouch_check : ShapeCast3D
@export var interaction_raycast : RayCast3D
@export_category("Stats")
@export var max_hp = 100 # Instantiate variable max_hp
@export var hp = 100 # Instantiate variable hp
@export_category("Movement Settings")
@export_group("Easing")
@export var acceleration := 0.2
@export var deceleration := 0.5
@export_group("Speed")
@export var default_speed : float = 7.0
@export var sprint_speed : float = 3.0
@export var crouch_speed : float = -5.0
@export_category("Jump Settings")
@export var jump_velocity = 4.5
@export_category("Miscellaneous")
@export var canRespawn : bool = true
@export var shot : PackedScene
@export var current_weapon : PackedScene
@export var animation_player : AnimationPlayer

@onready var hand = $CameraController/Camera3D/Hand
@onready var basic_rifle_hr = preload("res://Scenes/basic_rifle_hr.tscn")
@onready var basic_rifle = preload("res://Scenes/basic_rifle.tscn")
@onready var basic_sniper_hr = preload("res://Scenes/basic_sniper_hr.tscn")
@onready var basic_sniper = preload("res://Scenes/basic_sniper.tscn")

# Private variables
var speed : float = 0.0
var _movement_velocity : Vector3 = Vector3.ZERO
var sprint_modifier : float = 0.0
var crouch_modifier : float = 0.0
var _input_dir : Vector2 = Vector2.ZERO
var canShoot = true
var _is_crouching : bool
var current_interactable = null
var weapon_to_spawn = null
var weapon_to_drop = null
var hovered_weapon_type = null
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") # Get the gravity from the project settings to be synced with RigidBody nodes.

# Classes
var weapon_data := {}

func _ready() -> void: # This function is called when the object this script is attached to is instantiated during play
	# set _speed to the default
	speed = default_speed
	# populate weapon_data class at runtime
	weapon_data = {
		"basic_rifle": {
			"world": basic_rifle,
			"hand": basic_rifle_hr
		},
		"basic_sniper": {
			"world": basic_sniper,
			"hand": basic_sniper_hr
		}
	}
func _process(_delta) -> void: # This function will handle all possible inputs (see project input map settings) and make them do something
	pass
func _input(event) -> void:
		
	# Allows for interaction with interactable objects using the "interact" key
	if event.is_action_pressed("interact"):
		activate()
		find_weapon_hand()
		spawn_weapon_hand()
		
	if event.is_action_pressed("attack"):
		shoot()
func _physics_process(delta) -> void: # This function is called every frame
	do_gravity(delta)
	do_movement()
	check_hover_collision()
	# Ensure the shapecast updates its collision info
	crouch_check.force_shapecast_update() 

	if crouch_check.is_colliding():
		for i in range(crouch_check.get_collision_count()):
			var collision_object = crouch_check.get_collider(i)
			var collision_point = crouch_check.get_collision_point(i)
			var collision_normal = crouch_check.get_collision_normal(i)
			# You can now use the collision_object (e.g., check its name, call a function, etc.)
			print("Collider name: ", collision_object.name)
			print("Collision point: ", collision_point)
			print("Collision normal: ", collision_normal)
func update_rotation(rotation_input) -> void:
	global_transform.basis = Basis.from_euler(rotation_input)
func do_gravity(delta) -> void: # Add the gravity.
	if not is_on_floor():
		velocity.y += get_gravity() * delta
func get_gravity() -> float:
	return -ProjectSettings.get_setting("physics/3d/default_gravity")
func do_movement() -> void: # Get the input direction and handle the movement/deceleration.
	var speed_modifier = sprint_modifier + crouch_modifier
	speed = default_speed + speed_modifier
	# Get the input direction and handle the movement/deceleration.
	_input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var current_velocity = Vector2(_movement_velocity.x, _movement_velocity.z)
	var direction = (transform.basis * Vector3(_input_dir.x, 0, _input_dir.y)).normalized()
	if direction:
		current_velocity = lerp(current_velocity, Vector2(direction.x, direction.z) * speed, acceleration)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, deceleration)
	_movement_velocity = Vector3(current_velocity.x, velocity.y, current_velocity.y)
	velocity = _movement_velocity
	move_and_slide()
# STATES
func crouch() -> void: # Plays "animation" for crouching when called
	crouch_modifier = crouch_speed
	standing_collision.disabled = true
	crouching_collision.disabled = false
func stand() -> void: # Plays "animation" for standing when called
	crouch_modifier = 0.0
	standing_collision.disabled = false
	crouching_collision.disabled = true
func sprint() -> void: # Modify speed by sprint_speed
	sprint_modifier = sprint_speed
func walk() -> void:
	sprint_modifier = 0.0 # Set speed back to default
func jump() -> void: # Handle jump.
	velocity.y += jump_velocity
# DAMAGE AND COLLISION
func take_dmg(dmg) -> void: # Simple function to allow player to take damage when hit
	hp -= dmg
func shoot() -> void: # Simple shoot function, using a prefab rather than a raycast
	var camera = $CameraController/Camera3D
	var space_state = camera.get_world_3d().direct_space_state
	var screen_center = get_viewport().size / 2
	var origin = camera.project_ray_origin(screen_center)
	var end = origin + camera.project_ray_normal(screen_center) * 1000
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	print(result)
	canShoot = true
func die() -> void: # Discontinue living
	queue_free()
func check_hover_collision() -> void:
	if interaction_raycast.is_colliding():
		var hover_collider = interaction_raycast.get_collider()
		if hover_collider and is_instance_valid(hover_collider) and hover_collider.has_method("interact") and hover_collider.has_method("show_label"):
			if current_interactable != hover_collider:
				if current_interactable != null:
					current_interactable.hide_label()
				current_interactable = hover_collider
				current_interactable.show_label()
		else:
			hide_current_label()
	else:
		hide_current_label()
func hide_current_label() -> void:
	if is_instance_valid(current_interactable):
		current_interactable.hide_label()
		current_interactable = null
func activate() -> void:
	var hit = interaction_raycast.get_collider()
	if interaction_raycast.is_colliding():
		if hit and hit.has_method("interact"):
			hit.interact()
# INSTANTIATION
func find_weapon_hand() -> void:
	if interaction_raycast.is_colliding():
		var collider = interaction_raycast.get_collider()
		if collider and collider.get("weapon_id"):
			var id = collider.get("weapon_id")
			if weapon_data.get(id):
				weapon_to_spawn = weapon_data[id]["hand"].instantiate()
	
	if hand.get_child_count() > 0:
		var held = hand.get_child(0)
		if held and held.get("weapon_id"):
			var id = held.get("weapon_id")
			if weapon_data.get(id):
				weapon_to_drop = weapon_data[id]["world"].instantiate()
func spawn_weapon_hand() -> void:
	if weapon_to_spawn != null:
		# Drop current weapon ONLY if it exists
		if hand.get_child_count() > 0 and weapon_to_drop != null:
			get_parent().add_child(weapon_to_drop)
			weapon_to_drop.global_transform = hand.global_transform
			if weapon_to_drop is RigidBody3D:
				weapon_to_drop.apply_impulse(-global_transform.basis.z * 2 + Vector3.DOWN * 10)
			hand.get_child(0).queue_free()
			weapon_to_drop = null
		# Remove pickup from world
		var pickup = interaction_raycast.get_collider()
		if pickup:
			pickup.queue_free()
		# Equip new weapon
		hand.add_child(weapon_to_spawn)
		weapon_to_spawn.global_transform = hand.global_transform
		weapon_to_spawn = null
