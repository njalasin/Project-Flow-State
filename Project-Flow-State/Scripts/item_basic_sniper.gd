extends RigidBody3D

@onready var label: Label3D = $Label3D
@export var weapon_id = "basic_sniper"

func _process(delta):
	pass
func interact():
	print("Picked up Basic Sniper")
	queue_free()
func show_label():
	label.visible = true
func hide_label():
	label.visible = false
