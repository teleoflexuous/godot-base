class_name ProperCameraDetailCoordinator
extends Node

signal detail_band_changed(previous: StringName, current: StringName)
signal detail_metric_changed(metric: float)

@export var enabled: bool = true:
	set(value):
		enabled = value
		if not enabled:
			_set_band_index(-1)
@export var source_path: NodePath
@export var profile: ProperCameraDetailProfile
@export var metric_source: ProperCameraRigTypes.DetailMetricSource = ProperCameraRigTypes.DetailMetricSource.DESIRED

var _source: Node
var _band_index: int = -1
var _last_metric: float = 0.0


func _ready() -> void:
	if not source_path.is_empty():
		set_source(get_node_or_null(source_path))


func _exit_tree() -> void:
	_disconnect_source()


func set_source(source: Node) -> void:
	if _source == source:
		return
	_disconnect_source()
	_source = source
	if _source != null and _source.has_signal(&"view_metrics_changed"):
		var callable: Callable = _on_view_metrics_changed
		var result: Error = _source.connect(&"view_metrics_changed", callable)
		if result != OK:
			push_warning("ProperCameraDetailCoordinator could not connect to view_metrics_changed.")
	if _source != null and _source.has_method(&"get_view_metrics"):
		var metrics: Variant = _source.call(&"get_view_metrics")
		if metrics is Dictionary:
			update_from_metrics(metrics as Dictionary)


func update_from_metrics(metrics: Dictionary) -> void:
	if not enabled or profile == null:
		return
	var key: StringName = (
		&"desired_world_units_per_pixel"
		if metric_source == ProperCameraRigTypes.DetailMetricSource.DESIRED
		else &"actual_world_units_per_pixel"
	)
	var value: Variant = metrics.get(key, metrics.get(&"world_units_per_pixel", 0.0))
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return
	update_metric(float(value))


func update_metric(metric: float) -> void:
	if not enabled or profile == null:
		return
	_last_metric = maxf(metric, 0.0)
	detail_metric_changed.emit(_last_metric)
	_set_band_index(profile.get_hysteretic_band_index(_last_metric, _band_index))


func get_current_band() -> StringName:
	return &"" if profile == null else profile.get_band_id(_band_index)


func get_current_metric() -> float:
	return _last_metric


func _on_view_metrics_changed(metrics: Dictionary) -> void:
	update_from_metrics(metrics)


func _set_band_index(value: int) -> void:
	if value == _band_index:
		return
	var previous: StringName = &"" if profile == null else profile.get_band_id(_band_index)
	_band_index = value
	var current: StringName = &"" if profile == null else profile.get_band_id(_band_index)
	detail_band_changed.emit(previous, current)


func _disconnect_source() -> void:
	if _source != null and is_instance_valid(_source):
		var callable: Callable = _on_view_metrics_changed
		if _source.is_connected(&"view_metrics_changed", callable):
			_source.disconnect(&"view_metrics_changed", callable)
	_source = null
