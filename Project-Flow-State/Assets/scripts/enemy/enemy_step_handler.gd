##
## Enemy Step Handler Script
## This is the script that allows enemies to climb stairs. This uses raycasts and collisions to "teleport" the
## entity up to the next step
##

class_name EnemyStepHandlerComponent extends Node

@export_category("References")
@export var enemy_controller : EnemyController
@export_category("Step Settings")
@export var surface_threshold : float = 0.3
@export var step_height : float = 0.5

var step_status = null

const FEET_ADJUSTED_HEIGHT: float = 0.05
const MIN_STEP_HEIGHT: float = 0.1
const MIN_MOVEMENT_LENGTH : float = 0.1
const MIN_DOT_VALUE : float = 0.5

func handle_step_climbing():
	for i in enemy_controller.get_slide_collision_count():
		var collision = enemy_controller.get_slide_collision(i)
		if _is_vertical_surface(collision):
			var measured_height = _measure_step_height(collision)
			if measured_height > MIN_STEP_HEIGHT and measured_height <= step_height and _is_valid_step_direction(collision):
				enemy_controller.global_position.y += measured_height
				enemy_controller.velocity = enemy_controller.previous_velocity
			break

func _is_vertical_surface(collision: KinematicCollision3D) -> bool:
	var normal = collision.get_normal()
	if abs(normal.y) <= surface_threshold:
		return true
	return _check_collision_surface(collision)

func _check_collision_surface(collision: KinematicCollision3D) -> bool:
	var space_state = enemy_controller.get_world_3d().direct_space_state
	var collision_point = collision.get_position()
	
	var enemy_feet = _get_enemy_feet_position()
	collision_point.y = enemy_feet.y
	
	var query = PhysicsRayQueryParameters3D.create(enemy_feet, collision_point)
	query.collision_mask = enemy_controller.collision_mask
	query.exclude = [enemy_controller.get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result and abs(result.normal.y) <= surface_threshold:
		return true
	return false

func _get_enemy_feet_position() -> Vector3:
	var feet_pos = enemy_controller.global_position
	if enemy_controller.standing_collision.shape.is_class("CapsuleShape3D"):
		feet_pos.y -= enemy_controller.standing_collision.shape.height / 2
	elif enemy_controller.standing_collision.shape.is_class("SphereShape3D"):
		feet_pos.y -= enemy_controller.standing_collision.shape.radius * -.1
	feet_pos.y += FEET_ADJUSTED_HEIGHT # small buffer
	return feet_pos

func _measure_step_height(collision: KinematicCollision3D) -> float:
	var space_state = enemy_controller.get_world_3d().direct_space_state
	var collision_point = collision.get_position()
	
	var enemy_feet = _get_enemy_feet_position()
	var enemy_head_y = enemy_controller.global_position.y
	if enemy_controller.standing_collision.shape.is_class("CapsuleShape3D"):
		enemy_head_y += enemy_controller.standing_collision.shape.height / 2
	elif enemy_controller.standing_collision.shape.is_class("SphereShape3D"):
		enemy_head_y += enemy_controller.standing_collision.shape.radius * -1
	var ray_start = Vector3(collision_point.x, enemy_head_y, collision_point.z)
	var ray_end = Vector3(collision_point.x, enemy_feet.y, collision_point.z)
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = enemy_controller.collision_mask
	query.exclude = [enemy_controller.get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position.y - enemy_feet.y
		
	return 0.0

func _is_valid_step_direction(collision: KinematicCollision3D) -> bool:
	var collision_normal = collision.get_normal()
	var movement_dir = enemy_controller.get_direction()
	var movement_direction = enemy_controller.transform.basis * Vector3(movement_dir.x, 0, movement_dir.y)
	if movement_direction.length() > MIN_MOVEMENT_LENGTH:
		movement_direction = movement_direction.normalized()
		var dot_product = movement_direction.dot(-collision_normal)
		return dot_product > MIN_DOT_VALUE
	return false
