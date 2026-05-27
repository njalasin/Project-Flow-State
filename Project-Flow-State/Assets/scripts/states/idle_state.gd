##
## Idle State Script
## This script runs when the player is grounded and not moving
##
##

extends PlayerState

func _on_idle_state_processing(delta: float) -> void:
	if player_controller and player_controller._input_dir.length() > 0:
		player_controller.state_chart.send_event("onMoving")
