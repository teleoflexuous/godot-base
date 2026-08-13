class_name CameraGuideContextRouter
extends Node

signal contexts_changed(contexts: Array[GUIDEMappingContext])

@export var context_set: CameraGuideContextSet
@export_flags("Keyboard", "Mouse", "Gamepad", "Touch") var device_mask: int = 15
@export_range(-1000, 1000, 1) var priority: int = 0
@export var active: bool = true
@export var disable_while_tree_paused: bool = true
@export var input_adapter: CameraInputAdapter
@export var manage_adapter_enabled: bool = true

var _enabled_contexts: Array[GUIDEMappingContext] = []
var _last_tree_paused: bool = false
var _refresh_queued: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_tree_paused = get_tree().paused
	refresh_deferred()


func _exit_tree() -> void:
	_disable_owned_contexts()


func _process(_delta: float) -> void:
	if get_tree().paused == _last_tree_paused:
		return
	_last_tree_paused = get_tree().paused
	refresh_deferred()


func set_active(is_active: bool) -> void:
	if active == is_active:
		return
	active = is_active
	refresh_deferred()


func set_device_mask(mask: int) -> void:
	var normalized: int = mask & 15
	if device_mask == normalized:
		return
	device_mask = normalized
	refresh_deferred()


func refresh_deferred() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_apply_contexts.call_deferred()


func get_owned_enabled_contexts() -> Array[GUIDEMappingContext]:
	return _enabled_contexts.duplicate()


func _apply_contexts() -> void:
	_refresh_queued = false
	if not is_inside_tree():
		return
	_disable_owned_contexts()
	var should_enable: bool = active and not (disable_while_tree_paused and get_tree().paused)
	if manage_adapter_enabled and input_adapter != null:
		input_adapter.set_input_enabled(should_enable)
	if not should_enable or context_set == null:
		contexts_changed.emit(_enabled_contexts)
		return
	var guide: Node = _guide()
	if guide == null:
		contexts_changed.emit(_enabled_contexts)
		return
	for context: GUIDEMappingContext in context_set.contexts_for_mask(device_mask):
		# Never disable unrelated gameplay or UI contexts.
		guide.call("enable_mapping_context", context, false, priority)
		_enabled_contexts.append(context)
	contexts_changed.emit(_enabled_contexts)


func _disable_owned_contexts() -> void:
	var guide: Node = _guide()
	if guide == null:
		_enabled_contexts.clear()
		return
	for context: GUIDEMappingContext in _enabled_contexts:
		guide.call("disable_mapping_context", context)
	_enabled_contexts.clear()


func _guide() -> Node:
	return get_node_or_null(NodePath("/root/GUIDE"))
