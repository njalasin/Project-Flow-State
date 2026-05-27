##
## Enemy Controller
## Functions similarly to the player controller with less logic. Inside is a step handler and all functions
## for collisions
##

class_name EnemyController extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var enemy_step_handler : EnemyStepHandlerComponent
@export var standing_collision : CollisionShape3D

@onready var nav = $NavigationAgent3D

var movement_direction: Vector3 = Vector3.ZERO
var speed = 3.5
var gravity = 9.8
var previous_velocity : Vector3 = Vector3.ZERO

func _process(delta) -> void:
	pass

func _physics_process(delta) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	if is_on_floor():
		enemy_step_handler.handle_step_climbing()
	previous_velocity = velocity
	# 'velocity' is a built-in property of CharacterBody3D and RigidBody3D
	movement_direction = velocity.normalized()

	var next_location = nav.get_next_path_position()
	var current_location = global_transform.origin
	var new_velocity = (next_location - current_location).normalized() * speed
	
	velocity = velocity.move_toward(new_velocity,0.25)
	move_and_slide()

func target_position(target) -> void:
	nav.target_position = target

func get_direction() -> Vector3:
	return movement_direction
	queue_free()

func _on_health_component_died():
	queue_free()
