class_name PlayerStateMachine extends Node

@export var debug : bool = false
@export_category("References")
@export var player_controller : PlayerController
@export var step_handler_component : StepHandlerComponent

func _process(delta: float) -> void:
	if player_controller:
		player_controller.state_chart.set_expression_property("Player Velocity", player_controller.velocity)
		player_controller.state_chart.set_expression_property("Player Hitting Head", player_controller.crouch_check.is_colliding())
		player_controller.state_chart.set_expression_property("Looking at: ", player_controller.interaction_raycast.get_collider())
		player_controller.state_chart.set_expression_property("Step: ", step_handler_component.step_status)
func _ready() -> void:
	for state in get_tree().get_nodes_in_group("player_states"):
		state.player_controller = player_controller
