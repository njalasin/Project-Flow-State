extends Node3D

@onready var target = get_tree().get_first_node_in_group("player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	get_tree().call_group("enemy" , "target_position" , target.global_transform.origin)
