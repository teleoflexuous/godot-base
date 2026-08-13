class_name ProperCameraDetailPropertyMapper
extends Node

@export var coordinator_path: NodePath
@export var bindings: Array[ProperCameraDetailPropertyBinding] = []

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
			push_warning("ProperCameraDetailPropertyMapper could not connect to its coordinator.")
		apply_band(_coordinator.get_current_band())


func apply_band(band_id: StringName) -> void:
	for index: int in range(bindings.size()):
		var binding: ProperCameraDetailPropertyBinding = bindings[index]
		if binding == null or not binding.values_by_band.has(band_id):
			continue
		var target: Node = get_node_or_null(binding.target_path)
		if target == null or not _has_property(target, binding.property_name):
			continue
		var value: Variant = binding.values_by_band[band_id]
		if _is_compatible_value(target.get(binding.property_name), value):
			target.set(binding.property_name, value)


func restore_originals() -> void:
	for index: int in range(bindings.size()):
		if not _original_values.has(index):
			continue
		var binding: ProperCameraDetailPropertyBinding = bindings[index]
		if binding == null:
			continue
		var target: Node = get_node_or_null(binding.target_path)
		if target != null and _has_property(target, binding.property_name):
			target.set(binding.property_name, _original_values[index])


func validate_bindings() -> PackedStringArray:
	var issues: PackedStringArray = []
	for index: int in range(bindings.size()):
		var binding: ProperCameraDetailPropertyBinding = bindings[index]
		if binding == null:
			issues.append("Binding %d is empty." % index)
			continue
		var target: Node = get_node_or_null(binding.target_path)
		if target == null:
			issues.append("Binding %d target does not exist." % index)
		elif not _has_property(target, binding.property_name):
			issues.append("Binding %d property '%s' does not exist." % [index, binding.property_name])
	return issues


func _capture_original_values() -> void:
	_original_values.clear()
	for index: int in range(bindings.size()):
		var binding: ProperCameraDetailPropertyBinding = bindings[index]
		if binding == null:
			continue
		var target: Node = get_node_or_null(binding.target_path)
		if target != null and _has_property(target, binding.property_name):
			_original_values[index] = target.get(binding.property_name)


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


func _is_compatible_value(current: Variant, next: Variant) -> bool:
	if current == null or next == null:
		return true
	return typeof(current) == typeof(next) or (
		typeof(current) in [TYPE_INT, TYPE_FLOAT] and typeof(next) in [TYPE_INT, TYPE_FLOAT]
	)
