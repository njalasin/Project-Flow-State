# Goal of this script is to capture how much the mouse moves vertically and horizontally for purposes of camera movement
class_name MouseCaptureComponent extends Node # Helps with typecasting and other scripts as well as organization

@export var debug : bool = false # Allows for disabling of debug code within the editor
@export_category("Mouse Capture Settings") # Helps to organize export variables
@export var current_mouse_mode : Input.MouseMode = Input.MOUSE_MODE_CAPTURED # Holds mouse in center of screen while hiding cursor
@export var mouse_sensitivity : float = 0.005

var _capture_mouse : bool
var _mouse_input : Vector2

func _ready() -> void: # Called once on the root nodes instantiation
	Input.mouse_mode = current_mouse_mode
func _unhandled_input(event : InputEvent) -> void: # Automatically triggers when an "unhandled" input occurs
	_capture_mouse = event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED # This checks if mouse has moved, and if our event is of mode MOUSE_MODE_CAPTURED allowing for use of menus/UI
	if _capture_mouse:
		_mouse_input.x += -event.relative.x * mouse_sensitivity
		_mouse_input.y += -event.relative.y * mouse_sensitivity
	if debug:
		print(_mouse_input)
func _process(delta: float) -> void: # Called every frame. 'delta' is the elapsed time since the previous frame.
	_mouse_input = Vector2.ZERO # Sets mouse input variable to zero every frame
