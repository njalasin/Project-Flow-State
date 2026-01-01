extends RigidBody3D

@onready var label: Label3D = $Label3D
var rotation_speed = 50.0 # Degrees per second on Y-axis

func _process(delta):
	pass
func interact():
	print("Picked up Basic Pistol")
	queue_free()
func show_label():
	label.visible = true
func hide_label():
	label.visible = false
