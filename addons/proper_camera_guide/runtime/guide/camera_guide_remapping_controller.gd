class_name ProperCameraGuideRemappingController
extends Node

enum CollisionResolution {
	CANCEL,
	REPLACE,
	SWAP,
}

signal configuration_changed()
signal detection_started(item: Variant)
signal detection_finished(item: Variant, input: GUIDEInput)
signal collision_resolution_requested(item: Variant, input: GUIDEInput, collisions: Array)

@export var mapping_contexts: Array[GUIDEMappingContext] = []
@export var context_router: ProperCameraGuideContextRouter
@export var detector: GUIDEInputDetector
@export var config_path: String = "user://camera_guide_remapping.tres"
@export var apply_on_ready: bool = true

var _remapper: GUIDERemapper = GUIDERemapper.new()
var _config: GUIDERemappingConfig = GUIDERemappingConfig.new()
var _detect_item: Variant
var _pending_item: Variant
var _pending_input: GUIDEInput
var _pending_collisions: Array = []


func _ready() -> void:
	if detector == null:
		detector = GUIDEInputDetector.new()
		add_child(detector)
	if not detector.detection_started.is_connected(_on_detection_started):
		detector.detection_started.connect(_on_detection_started)
	if not detector.input_detected.is_connected(_on_input_detected):
		detector.input_detected.connect(_on_input_detected)
	load_configuration()
	_remapper.initialize(mapping_contexts, _config)
	if apply_on_ready:
		apply_configuration()


func initialize(contexts: Array[GUIDEMappingContext], config: GUIDERemappingConfig = null) -> void:
	mapping_contexts = contexts.duplicate()
	_config = config.duplicate(true) as GUIDERemappingConfig if config != null else GUIDERemappingConfig.new()
	_remapper.initialize(mapping_contexts, _config)


func get_remappable_items() -> Array:
	return _remapper.get_remappable_items()


func get_bound_input_or_null(item: Variant) -> GUIDEInput:
	return _remapper.get_bound_input_or_null(item)


func begin_detection(item: Variant, device_types: Array = []) -> bool:
	if detector == null or detector.is_detecting or item == null:
		return false
	# GUIDE v0.14 deliberately cannot detect touch remaps. Touch gestures stay fixed.
	if device_types.has(GUIDEInput.DeviceType.TOUCH):
		return false
	_detect_item = item
	match item.value_type:
		GUIDEAction.GUIDEActionValueType.BOOL:
			detector.detect_bool(device_types)
		GUIDEAction.GUIDEActionValueType.AXIS_1D:
			detector.detect_axis_1d(device_types)
		GUIDEAction.GUIDEActionValueType.AXIS_2D:
			detector.detect_axis_2d(device_types)
		GUIDEAction.GUIDEActionValueType.AXIS_3D:
			detector.detect_axis_3d(device_types)
		_:
			_detect_item = null
			return false
	return true


func request_binding(item: Variant, input: GUIDEInput) -> bool:
	if item == null:
		return false
	var collisions: Array = _remapper.get_input_collisions(item, input)
	if collisions.is_empty():
		_remapper.set_bound_input(item, input)
		_commit_edited_config()
		return true
	_pending_item = item
	_pending_input = input
	_pending_collisions = collisions
	collision_resolution_requested.emit(item, input, collisions)
	return false


func resolve_collision(resolution: CollisionResolution) -> bool:
	if _pending_item == null:
		return false
	var changed: bool = false
	match resolution:
		CollisionResolution.CANCEL:
			pass
		CollisionResolution.REPLACE:
			for collision: Variant in _pending_collisions:
				_remapper.set_bound_input(collision, null)
			_remapper.set_bound_input(_pending_item, _pending_input)
			changed = true
		CollisionResolution.SWAP:
			if _pending_collisions.size() == 1:
				var displaced_input: GUIDEInput = _remapper.get_bound_input_or_null(_pending_item)
				_remapper.set_bound_input(_pending_item, _pending_input)
				_remapper.set_bound_input(_pending_collisions[0], displaced_input)
				changed = true
	_clear_pending_collision()
	if changed:
		_commit_edited_config()
	return changed


func restore_default(item: Variant) -> void:
	_remapper.restore_default_for(item)
	_commit_edited_config()


func reset_all() -> void:
	_config = GUIDERemappingConfig.new()
	_remapper.initialize(mapping_contexts, _config)
	apply_configuration()
	configuration_changed.emit()


func apply_configuration() -> void:
	var guide: Node = get_node_or_null(NodePath("/root/GUIDE"))
	if guide != null:
		guide.call("set_remapping_config", _config)


func save_configuration(path: String = config_path) -> bool:
	_config = _remapper.get_mapping_config()
	return ResourceSaver.save(_config, path) == OK


func save_and_apply(path: String = config_path) -> bool:
	var saved: bool = save_configuration(path)
	if saved:
		apply_configuration()
	return saved


func load_configuration(path: String = config_path) -> bool:
	if not ResourceLoader.exists(path):
		_config = GUIDERemappingConfig.new()
		return false
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded is not GUIDERemappingConfig:
		_config = GUIDERemappingConfig.new()
		return false
	_config = loaded as GUIDERemappingConfig
	return true


func is_touch_remapping_supported() -> bool:
	return false


func _commit_edited_config() -> void:
	_config = _remapper.get_mapping_config()
	configuration_changed.emit()


func _clear_pending_collision() -> void:
	_pending_item = null
	_pending_input = null
	_pending_collisions.clear()


func _on_detection_started() -> void:
	detection_started.emit(_detect_item)


func _on_input_detected(input: GUIDEInput) -> void:
	var completed_item: Variant = _detect_item
	_detect_item = null
	if input != null and completed_item != null:
		request_binding(completed_item, input)
	if context_router != null:
		# GUIDE's detector restores contexts at default priorities; reapply only the
		# contexts owned by this camera router with their authored priority.
		context_router.refresh_deferred()
	detection_finished.emit(completed_item, input)
