##
## Enemy Grunt Script
## This is the script that all "Grunt" enemies use for logic and AI
##
##

class_name EnemyGrunt extends EnemyBase

@export var follow_speed: float = 3.0
@export var acceleration: float = 15.0
@export var deceleration: float = 20.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var state_chart: StateChart = $StateChart
@onready var health_component = $HealthComponent
@onready var animation_player: AnimationPlayer = $GruntModel/AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree

var target: Node3D
var anim_tree_state: AnimationNodeStateMachinePlayback
var temp: bool = true
# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()

	# Find Player
	target = get_tree().get_first_node_in_group("player")
	
	# Connect Signals
	health_component.died.connect(_on_died)
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	
	anim_tree_state = anim_tree["parameters/playback"]
	
	await get_tree().process_frame
	anim_tree["parameters/Idle/TimeSeek/seek_request"] = randf_range(0.0, 1.0)
	
func _physics_process(delta: float) -> void:
	# apply gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
		
	move_and_slide()
	update_blends()
	
func on_triggered() -> void:
	state_chart.send_event("toFollow")

func _on_died() -> void:
	queue_free()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	var target_velocity = Vector3(safe_velocity.x, velocity.y, safe_velocity.z)
	var accel = acceleration if safe_velocity.length() > 0.01 else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * get_physics_process_delta_time())
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * get_physics_process_delta_time())
	
func _on_follow_state_physics_processing(delta):
	if anim_tree_state.get_current_node() != "Follow":
		anim_tree_state.travel("Follow")
	
	if not target:
		return
	
	# Set target position for navigation
	nav_agent.target_position = target.global_position
	
	# Check if navigation finished
	if nav_agent.is_navigation_finished():
		nav_agent.velocity = Vector3.ZERO
		if animation_player and animation_player.current_animation != "Fighting Idle":
			animation_player.play("Fighting Idle")
		return
	
	# Get next position in path
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	
	# Set desired velocity (NavigationAgent handles avoidance)
	nav_agent.velocity = direction * follow_speed
		
	if not nav_agent.avoidance_enabled:
		var target_velocity_x = direction.x * follow_speed
		var target_velocity_z = direction.z * follow_speed
		
		velocity.x = move_toward(velocity.x, target_velocity_x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity_z, deceleration * delta)
	# Rotate to face movement direction
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 5.0 * delta)


func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		on_triggered()

func update_blends() -> void:
	var move_amount = velocity.length()
	move_amount = remap(move_amount, 0.0, follow_speed, 0.0, 1.0)
	anim_tree["parameters/Follow/IdleChaseBlend/blend_position"] = move_amount
