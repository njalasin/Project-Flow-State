##
## Main Scene Script
## This script allows for some development tools within the main scene such as spawning enemies for testing
##
##

extends Node

@export var enemyToSpawn: PackedScene

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		var enemyInstance = enemyToSpawn.instantiate()
		get_tree().root.get_node("MainScene/CurrentLevel").add_child(enemyInstance)
