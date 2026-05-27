##
## Walking State Script
## This script is the state for when the player is moving but not sprinting and is grounded
##
##

extends PlayerState

func _on_walking_state_processing(delta: float) -> void:
	if Input.is_action_pressed("sprint"):
		player_controller.state_chart.send_event("onSprinting")


func _on_walking_state_entered() -> void:
	player_controller.walk()
