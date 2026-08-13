class_name ProperCameraEdgeScroll
extends Node

## Optional edge-scroll producer. Place it beside either camera input adapter.
## UI can block it by setting ui_blocked while a modal, selection drag, or
## pointer-consuming control is active.

@export var input_adapter_path: NodePath
@export var enabled: bool = false
@export_range(0.0, 128.0, 1.0) var margin: float = 24.0
@export var require_pointer_inside_window: bool = true

var ui_blocked: bool = false
var drag_blocked: bool = false
var _input_adapter: ProperCameraInputAdapter


func _ready() -> void:
	_input_adapter = get_node_or_null(input_adapter_path) as ProperCameraInputAdapter


func _process(delta: float) -> void:
	if not enabled or ui_blocked or drag_blocked or not is_instance_valid(_input_adapter):
		return
	if not _input_adapter.input_enabled or not DisplayServer.window_is_focused():
		return
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var pointer: Vector2 = get_viewport().get_mouse_position()
	if require_pointer_inside_window and not viewport_rect.has_point(pointer):
		return
	var direction: Vector2 = Vector2.ZERO
	var left: float = viewport_rect.position.x + margin
	var right: float = viewport_rect.end.x - margin
	var top: float = viewport_rect.position.y + margin
	var bottom: float = viewport_rect.end.y - margin
	if pointer.x <= left:
		direction.x = -1.0
	elif pointer.x >= right:
		direction.x = 1.0
	if pointer.y <= top:
		direction.y = -1.0
	elif pointer.y >= bottom:
		direction.y = 1.0
	_input_adapter.submit_pan_rate(direction.limit_length(), delta)


func set_ui_blocked(blocked: bool) -> void:
	ui_blocked = blocked


func set_drag_blocked(blocked: bool) -> void:
	drag_blocked = blocked
