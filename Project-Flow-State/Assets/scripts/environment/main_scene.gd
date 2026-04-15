extends Node

@export var enemyToSpawn: PackedScene

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		var enemyInstance = enemyToSpawn.instantiate()
		$CurrentLevel.add_child(enemyInstance)
