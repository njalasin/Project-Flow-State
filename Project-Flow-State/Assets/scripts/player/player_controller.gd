extends PlayerController

# Exported variables
@export var debug : bool = false
@export_category("References")
@export var camera : CameraController
@export var camera_effects : CameraEffects
@export var weapon_controller : WeaponController
@export var state_chart : StateChart
@export var standing_collision : CollisionShape3D
@export var crouching_collision : CollisionShape3D
@export var crouch_check : ShapeCast3D
@export var interaction_raycast : RayCast3D
@export var step_handler : StepHandlerComponent
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
@export var jump_velocity: float = 4.5
@export var fall_velocity_threshold : float = -5.0
@export_category("Miscellaneous")
@export var canRespawn : bool = true

# Private variables
var speed : float = 0.0
var _movement_velocity : Vector3 = Vector3.ZERO
var sprint_modifier : float = 0.0
var crouch_modifier : float = 0.0
var _input_dir : Vector2 = Vector2.ZERO
var current_fall_velocity : float
var previous_velocity : Vector3

func _ready() -> void: # This function is called when the object this script is attached to is instantiated during play
	# set _speed to the default
	speed = default_speed
func _process(_delta) -> void: # This function will handle all possible inputs (see project input map settings) and make them do something
	pass
func _input(event) -> void:
	pass
func _physics_process(delta) -> void: # This function is called every frame
	do_movement()
	if not is_on_floor():
		velocity += get_gravity() * delta
	previous_velocity = velocity
	move_and_slide()
	if is_on_floor():
		step_handler.handle_step_climbing()
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
func get_input_direction() -> Vector2:
	return _input_dir
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
func check_fall_speed() -> bool:
	if current_fall_velocity < fall_velocity_threshold:
		current_fall_velocity = 0.0
		return true
	else:
		current_fall_velocity = 0.0
		return false
# DAMAGE AND COLLISION
func take_dmg(dmg) -> void: # Simple function to allow player to take damage when hit
	hp -= dmg
func die() -> void: # Discontinue living
	queue_free()
