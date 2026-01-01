extends CharacterBody3D

# Exported variables
@export var max_hp = 100 # Instantiate variable max_hp
@export var hp = 100 # Instantiate variable hp
@export var speed_default : float = 5.0
@export var speed_crouch : float = 2.0
@export var sprint_mult : float = 2.0
@export var fall_acceleration = 75
@export var jump_velocity = 4.5
@export var shot : PackedScene
@export var player : PackedScene
@export var current_weapon : PackedScene
@export var mouse_sensitivity : float = 0.5
@export var tilt_lower_limit := deg_to_rad(-90.0)
@export var tilt_upper_limit := deg_to_rad(90.0)
@export var camera_controller : Camera3D
@export var animation_player : AnimationPlayer
@export var crouch_shapecast : Node3D
@export var canRespawn : bool = true
@export_range(5, 10, 0.1) var crouch_speed : float = 7.0

@onready var camera = $Pivot/Camera3D
@onready var raycast = $Pivot/Camera3D/InteractionRay
@onready var hand = $Pivot/Camera3D/Hand
@onready var basic_rifle_hr = preload("res://Scenes/basic_rifle_hr.tscn")
@onready var basic_rifle = preload("res://Scenes/basic_rifle.tscn")
@onready var basic_sniper_hr = preload("res://Scenes/basic_sniper_hr.tscn")
@onready var basic_sniper = preload("res://Scenes/basic_sniper.tscn")
# Private variables
var _speed : float
var canShoot = true
var target_velocity = Vector3.ZERO
var _player_rotation : Vector3
var _camera_rotation : Vector3
var _mouse_input : bool = false
var _mouse_rotation : Vector3
var _rotation_input : float
var _tilt_input : float
var _is_crouching : bool = false
var current_interactable = null
var weapon_to_spawn = null
var weapon_to_drop = null
var hovered_weapon_type = null
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Classes
var weapon_data := {}

# This function is called when the object this script is attached to is instantiated during play
func _ready():
	# Get mouse input
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Set speed to default
	_speed = speed_default
	# add crouch check shapecast collision exception for CharacterBody3D node
	crouch_shapecast.add_exception($".")
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
func _process(_delta):
	pass
# This function will handle all possible inputs (see project input map settings) and make them do something
func _input(event):
	# Quits the game is "exit" key is pressed
	if event.is_action_pressed("exit"):
		get_tree().quit()
	
	# Sets Player transform to original "spawn" point
	if event.is_action_pressed("respawn"):
		global_transform = Transform3D.IDENTITY
		global_transform.origin = Vector3(0, 1, 0)
		
	# Crouches/uncrouches the player when "crouch_toggle" key is pressed
	if event.is_action_pressed("crouch_toggle") && is_on_floor():
		toggle_crouch()
		
	# Crouches/uncrouches the player when "crouch" key is held down or released (respectively)
	if event.is_action_pressed("crouch") && crouch_shapecast.is_colliding() == false && is_on_floor():
		crouching(true)
	if event.is_action_released("crouch") && is_on_floor():
		if crouch_shapecast.is_colliding() == false:
			crouching(false)
			_is_crouching = false
		elif crouch_shapecast.is_colliding() == true:
			uncrouch_check()
	
	# Allows for interaction with interactable objects using the "interact" key
	if event.is_action_pressed("interact"):
		activate()
		find_weapon_hand()
		spawn_weapon_hand()
# This function is called every frame
func _physics_process(delta):
	do_gravity(delta)
	_update_camera(delta)
	jump()
	do_movement()
	move_and_slide()
	check_hover_collision()
# Add the gravity.
func do_gravity(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
# Handle jump.
func jump():
	if Input.is_action_just_pressed("jump") and is_on_floor() && _is_crouching == false:
		velocity.y = jump_velocity
# Get the input direction and handle the movement/deceleration.
func do_movement():
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction && Input.is_action_pressed("sprint"):
		velocity.x = direction.x * _speed * sprint_mult
		velocity.z = direction.z * _speed * sprint_mult
	elif direction:
		velocity.x = direction.x * _speed
		velocity.z = direction.z * _speed
	else:
		velocity.x = move_toward(velocity.x, 0, _speed)
		velocity.z = move_toward(velocity.z, 0, _speed)
# This function allows mouse controls to exist
func _unhandled_input(event):
	_mouse_input = event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * mouse_sensitivity
		_tilt_input = -event.relative.y * mouse_sensitivity
# This function rotates the camera relative to player mouse movements
func _update_camera(delta):
	
	# Rotate camera using euler rotation
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, tilt_lower_limit, tilt_upper_limit)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)
	
	camera_controller.transform.basis = Basis.from_euler(_camera_rotation)
	camera_controller.rotation.z = 0.0
	
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	_rotation_input = 0.0
	_tilt_input = 0.0
# Crouch/uncrouch the player when able
func toggle_crouch():
	if _is_crouching == true && crouch_shapecast.is_colliding() == false:
		crouching(false)
	elif _is_crouching == false:
		crouching(true)
# Plays animation for crouching when called
func crouching(state : bool):
	match state:
		true:
			animation_player.play("Crouch", 0, crouch_speed)
			animation_player.seek(0.0, true)
			set_movement_speed("crouching")
		false:
			animation_player.play("Crouch", 0, -crouch_speed, true)
			set_movement_speed("default")
# For use with non toggled crouching, makes sure player is able to stand up when exiting smaller areas
func uncrouch_check():
	if crouch_shapecast.is_colliding() == false:
		crouching(false)
	if crouch_shapecast.is_colliding() == true:
		await get_tree().create_timer(0.1).timeout
		uncrouch_check()
# Simple function to allow player to take damage when hit
func take_dmg(dmg):
	hp -= dmg
	if(hp<=0):
		die()
# Simple shoot function, using a prefab rather than a raycast
func shoot():
	var shot = shot.instantiate()
	get_tree().current_scene.add_child(shot)
	
	canShoot = false
	$ShootTimer.start()	
func on_shoot_timer_timeout():
	canShoot = true
func die():
	queue_free()
	if(canRespawn == true):
		respawn()
# Called when animation player starts
func _on_animation_player_animation_started(anim_name):
	if anim_name == "Crouch":
		_is_crouching = !_is_crouching
# Allows for dynamic movement speed alterations
# When using this function, pass in a string listed in the match statement
func set_movement_speed(state : String):
	
	match state:
		"default":
			_speed = speed_default
		"crouching":
			_speed = speed_crouch
func respawn():
	var player = player.instantiate()
	print("respawned")
	get_tree().current_scene.add_child(player)
func check_hover_collision():
	if raycast.is_colliding():
		var hover_collider = raycast.get_collider()
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
func hide_current_label():
	if is_instance_valid(current_interactable):
		current_interactable.hide_label()
		current_interactable = null
func activate():
	var hit = raycast.get_collider()
	if raycast.is_colliding():
		if hit and hit.has_method("interact"):
			hit.interact()
func find_weapon_hand():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
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
func spawn_weapon_hand():
	if weapon_to_spawn != null:
		# Drop current weapon ONLY if it exists
		if hand.get_child_count() > 0 and weapon_to_drop != null:
			get_parent().add_child(weapon_to_drop)
			weapon_to_drop.global_transform = hand.global_transform
			if weapon_to_drop is RigidBody3D:
				weapon_to_drop.apply_impulse(Vector3(3, 0, 0))
			hand.get_child(0).queue_free()
			weapon_to_drop = null
		# Remove pickup from world
		var pickup = raycast.get_collider()
		if pickup:
			pickup.queue_free()
		# Equip new weapon
		hand.add_child(weapon_to_spawn)
		weapon_to_spawn.global_transform = hand.global_transform
		weapon_to_spawn = null
