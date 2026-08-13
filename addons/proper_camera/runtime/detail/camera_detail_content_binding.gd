class_name ProperCameraDetailContentBinding
extends Node

@export var coordinator_path: NodePath
@export var targets: Array[NodePath] = []
@export var visible_bands: Array[StringName] = []
@export var processing_bands: Array[StringName] = []

var _coordinator: ProperCameraDetailCoordinator
var _original_values: Dictionary = {}


func _ready() -> void:
	_capture_original_values()
	if not coordinator_path.is_empty():
		set_coordinator(get_node_or_null(coordinator_path) as ProperCameraDetailCoordinator)


func _exit_tree() -> void:
	_disconnect_coordinator()
	restore_originals()


func set_coordinator(coordinator: ProperCameraDetailCoordinator) -> void:
	if _coordinator == coordinator:
		return
	_disconnect_coordinator()
	_coordinator = coordinator
	if _coordinator != null:
		var result: Error = _coordinator.detail_band_changed.connect(_on_detail_band_changed)
		if result != OK:
			push_warning("ProperCameraDetailContentBinding could not connect to its coordinator.")
		apply_band(_coordinator.get_current_band())


func apply_band(band_id: StringName) -> void:
	for target_path: NodePath in targets:
		var target: Node = get_node_or_null(target_path)
		if target == null:
			continue
		if _has_property(target, &"visible") and not visible_bands.is_empty():
			target.set(&"visible", visible_bands.has(band_id))
		if not processing_bands.is_empty():
			target.process_mode = (
				Node.PROCESS_MODE_INHERIT
				if processing_bands.has(band_id)
				else Node.PROCESS_MODE_DISABLED
			)


func restore_originals() -> void:
	for target_path: NodePath in targets:
		var target: Node = get_node_or_null(target_path)
		var key: String = String(target_path)
		if target == null or not _original_values.has(key):
			continue
		var values: Dictionary = _original_values[key] as Dictionary
		if values.has(&"visible") and _has_property(target, &"visible"):
			target.set(&"visible", values[&"visible"])
		if values.has(&"process_mode"):
			target.process_mode = int(values[&"process_mode"]) as Node.ProcessMode


func _capture_original_values() -> void:
	_original_values.clear()
	for target_path: NodePath in targets:
		var target: Node = get_node_or_null(target_path)
		if target == null:
			continue
		var values: Dictionary = {&"process_mode": target.process_mode}
		if _has_property(target, &"visible"):
			values[&"visible"] = target.get(&"visible")
		_original_values[String(target_path)] = values


func _on_detail_band_changed(_previous: StringName, current: StringName) -> void:
	apply_band(current)


func _disconnect_coordinator() -> void:
	if _coordinator != null and is_instance_valid(_coordinator):
		var callable: Callable = _on_detail_band_changed
		if _coordinator.detail_band_changed.is_connected(callable):
			_coordinator.detail_band_changed.disconnect(callable)
	_coordinator = null


func _has_property(object: Object, property_name: StringName) -> bool:
	for property: Dictionary in object.get_property_list():
		if StringName(property.get(&"name", &"")) == property_name:
			return true
	return false
