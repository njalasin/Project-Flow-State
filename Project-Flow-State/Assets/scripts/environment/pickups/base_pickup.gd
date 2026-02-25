class_name BasePickup extends Area3D

@export var rotation_speed: float = 60.0
@export var float_height: float = 0.1
@export var float_speed: float = 2.0

var start_y: float
var time: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_pickup)
	start_y = position.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Bobbing animation
	time += delta
	position.y = start_y + sin(time * float_speed) * float_height
	
	# Rotation animation
	rotate_y(deg_to_rad(rotation_speed) * delta)

func _on_pickup(body: Node3D) -> void:
	if not body is PlayerController:
		return
	
	if can_pickup(body):
		apply_pickup(body)
		queue_free()

func can_pickup(player: PlayerController) -> bool:
	return true

func apply_pickup(player: PlayerController) -> void:
	pass
