extends RigidBody3D

@onready var label: Label3D = $Label3D
var dropped = false

func _process(delta):
	if dropped == true:
		apply_impulse(Vector3(3, 0, 0))
		dropped = false
func interact():
	print("Picked up Basic Rifle")
	queue_free()
func show_label():
	label.visible = true
func hide_label():
	label.visible = false
