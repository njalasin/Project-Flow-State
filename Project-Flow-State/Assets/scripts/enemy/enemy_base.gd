##
## Enemy Base Script
## This is the parent script for all enemy types
##
##

class_name EnemyBase extends CharacterBody3D

@export var enemy_groups: Array[String] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for group in enemy_groups:
		add_to_group(group)

func on_triggered() -> void:
	# Override in child classes
	pass
