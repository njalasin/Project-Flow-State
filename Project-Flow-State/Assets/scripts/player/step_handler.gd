##
## Step Handler Script
## This script handles stair logic for the player. Without this the player cannot climb stairs.
##
##

class_name StepHandlerComponent extends Node

@export_category("References")
@export var player_controller : PlayerController
@export_category("Step Settings")
@export var surface_threshold : float = 0.3
@export var step_height : float = 0.5

var step_status = null

const FEET_ADJUSTED_HEIGHT: float = 0.05
const MIN_STEP_HEIGHT: float = 0.1
const MIN_MOVEMENT_LENGTH : float = 0.1
const MIN_DOT_VALUE : float = 0.2

func handle_step_climbing():
	step_status = "No vertical collision detected"
	# Calculate probe_offset once here, share it with both functions
	var input_dir = player_controller.get_input_direction()
	var movement_direction = (player_controller.transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	
	if movement_direction.length() <= MIN_MOVEMENT_LENGTH:
		movement_direction = player_controller.velocity
		movement_direction.y = 0.0
		
	var probe_offset = Vector3.ZERO
	if movement_direction.length() > MIN_MOVEMENT_LENGTH:
		probe_offset = movement_direction.normalized() * 0.15

	for i in player_controller.get_slide_collision_count():
		var collision = player_controller.get_slide_collision(i)
		if _is_vertical_surface(collision):
			var measured_height = _measure_step_height(collision, probe_offset)
			if measured_height <= 0.0:
				step_status = "No step surface found"
				continue
			measured_height += 0.05  # apply bias here instead of inside _measure_step_height
			if measured_height > MIN_STEP_HEIGHT and measured_height <= step_height + 0.05 and _is_valid_step_direction(collision) and _is_space_clear_at_height(measured_height, probe_offset):
				# Push away from wall slightly before stepping up
				var push_back = collision.get_normal() * 0.05
				player_controller.global_position += push_back
				player_controller.global_position.y += measured_height
				player_controller.velocity.y = 0.0
				player_controller.camera.smooth_step(measured_height)
			step_status = "Step too high or invalid: " + str(measured_height)
func _is_vertical_surface(collision: KinematicCollision3D) -> bool:
	var normal = collision.get_normal()
	if abs(normal.y) <= surface_threshold:
		step_status = "CollisionShape: Vertical Collision Found!" + str(normal)
		return true
	return _check_collision_surface(collision)
func _check_collision_surface(collision: KinematicCollision3D) -> bool:
	var space_state = player_controller.get_world_3d().direct_space_state
	var collision_point = collision.get_position()
	
	var player_feet = _get_player_feet_position()
	collision_point.y = player_feet.y
	
	var query = PhysicsRayQueryParameters3D.create(player_feet, collision_point)
	query.collision_mask = player_controller.collision_mask
	query.exclude = [player_controller.get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result and abs(result.normal.y) <= surface_threshold:
		step_status = "Raycast: Vertical collison found! " + str(result.normal)
		return true
	step_status = "No vertical collision detected"
	return false
func _get_player_feet_position() -> Vector3:
	var feet_pos = player_controller.global_position
	feet_pos.y -= player_controller.standing_collision.shape.height / 2
	feet_pos.y += FEET_ADJUSTED_HEIGHT # small buffer
	return feet_pos
func _measure_step_height(collision: KinematicCollision3D, probe_offset: Vector3) -> float:
	# The key changes are that probe_offset is now calculated once in handle_step_climbing() and passed down, the bias is applied at the call site after _measure_step_height() returns so the clearance check sees the true final height, and _measure_step_height() no longer duplicates the movement direction calculation that handle_step_climbing() already does.
	var space_state = player_controller.get_world_3d().direct_space_state
	
	var collision_point = collision.get_position()
	var player_feet = _get_player_feet_position()
	var player_head_y = player_controller.global_position.y + (player_controller.standing_collision.shape.height / 2)
	
	var sample_pos = Vector3(
		collision_point.x + probe_offset.x,
		player_head_y,
		collision_point.z + probe_offset.z
	)
	
	var query = PhysicsRayQueryParameters3D.create(sample_pos, Vector3(sample_pos.x, player_feet.y, sample_pos.z))
	query.collision_mask = player_controller.collision_mask
	query.exclude = [player_controller.get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position.y - player_feet.y  # bias removed from here
		
	return 0.0
func _is_valid_step_direction(collision: KinematicCollision3D) -> bool:
	var collision_normal = collision.get_normal()
	var input_dir = player_controller.get_input_direction()
	var movement_direction = player_controller.transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	# Fall back to actual horizontal velocity if no input
	if movement_direction.length() <= MIN_MOVEMENT_LENGTH:
		movement_direction = player_controller.velocity
		movement_direction.y = 0.0  # ignore vertical component
	if movement_direction.length() > MIN_MOVEMENT_LENGTH:
		movement_direction = movement_direction.normalized()
		var dot_product = movement_direction.dot(-collision_normal)
		return dot_product > MIN_DOT_VALUE
	return false
func _is_space_clear_at_height(height_offset: float, horizontal_offset: Vector3 = Vector3.ZERO) -> bool:
	var space_state = player_controller.get_world_3d().direct_space_state
	var shape_query = PhysicsShapeQueryParameters3D.new()
	
	var shape = player_controller.standing_collision.shape.duplicate()
	# Shrink the capsule radius slightly to add a safety margin
	shape.radius = max(shape.radius - 0.05, 0.1)
	shape_query.shape = shape
	shape_query.collision_mask = player_controller.collision_mask
	shape_query.exclude = [player_controller.get_rid()]
	   
	var test_transform = player_controller.global_transform
	test_transform.origin.y += height_offset
	test_transform.origin += horizontal_offset
	shape_query.transform = test_transform
	   
	var results = space_state.intersect_shape(shape_query, 1)
	return results.is_empty()
