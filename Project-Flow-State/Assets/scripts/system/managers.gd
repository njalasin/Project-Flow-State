##
## Manager Script
## This is the parent script for all manager scripts
##
##

extends Node

var weapon_manager := WeaponManager.new()

func _ready() -> void:
	call_deferred("find_managers")

func find_managers() -> void:
	weapon_manager = get_tree().get_first_node_in_group("weapon_manager")
