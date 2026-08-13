class_name ProperCameraUserPreferences
extends Resource

const MIN_SENSITIVITY: float = 0.01
const MAX_SENSITIVITY: float = 10.0

@export_range(MIN_SENSITIVITY, MAX_SENSITIVITY, 0.01) var horizontal_sensitivity: float = 1.0
@export_range(MIN_SENSITIVITY, MAX_SENSITIVITY, 0.01) var vertical_sensitivity: float = 1.0
@export_range(MIN_SENSITIVITY, MAX_SENSITIVITY, 0.01) var zoom_sensitivity: float = 1.0
@export var invert_horizontal: bool = false
@export var invert_vertical: bool = false
@export var invert_zoom: bool = false
@export var edge_pan_enabled: bool = true
@export var auto_recenter_enabled: bool = false
@export_range(0.0, 30.0, 0.05, "or_greater") var auto_recenter_delay: float = 2.0
@export_range(0.0, 30.0, 0.05, "or_greater") var auto_recenter_speed: float = 4.0
@export var fov_override_enabled: bool = false
@export_range(1.0, 179.0, 0.5) var preferred_fov_degrees: float = 75.0
@export var distance_override_enabled: bool = false
@export_range(0.0, 10000.0, 0.1, "or_greater") var preferred_distance: float = 4.0
@export_range(0.0, 1.0, 0.01) var motion_intensity: float = 1.0


func sanitize() -> void:
	horizontal_sensitivity = clampf(horizontal_sensitivity, MIN_SENSITIVITY, MAX_SENSITIVITY)
	vertical_sensitivity = clampf(vertical_sensitivity, MIN_SENSITIVITY, MAX_SENSITIVITY)
	zoom_sensitivity = clampf(zoom_sensitivity, MIN_SENSITIVITY, MAX_SENSITIVITY)
	auto_recenter_delay = maxf(auto_recenter_delay, 0.0)
	auto_recenter_speed = maxf(auto_recenter_speed, 0.0)
	preferred_fov_degrees = clampf(preferred_fov_degrees, 1.0, 179.0)
	preferred_distance = maxf(preferred_distance, 0.0)
	motion_intensity = clampf(motion_intensity, 0.0, 1.0)


func to_dictionary() -> Dictionary:
	return {
		"horizontal_sensitivity": horizontal_sensitivity,
		"vertical_sensitivity": vertical_sensitivity,
		"zoom_sensitivity": zoom_sensitivity,
		"invert_horizontal": invert_horizontal,
		"invert_vertical": invert_vertical,
		"invert_zoom": invert_zoom,
		"edge_pan_enabled": edge_pan_enabled,
		"auto_recenter_enabled": auto_recenter_enabled,
		"auto_recenter_delay": auto_recenter_delay,
		"auto_recenter_speed": auto_recenter_speed,
		"fov_override_enabled": fov_override_enabled,
		"preferred_fov_degrees": preferred_fov_degrees,
		"distance_override_enabled": distance_override_enabled,
		"preferred_distance": preferred_distance,
		"motion_intensity": motion_intensity,
	}


func apply_dictionary(values: Dictionary) -> void:
	horizontal_sensitivity = float(values.get("horizontal_sensitivity", horizontal_sensitivity))
	vertical_sensitivity = float(values.get("vertical_sensitivity", vertical_sensitivity))
	zoom_sensitivity = float(values.get("zoom_sensitivity", zoom_sensitivity))
	invert_horizontal = bool(values.get("invert_horizontal", invert_horizontal))
	invert_vertical = bool(values.get("invert_vertical", invert_vertical))
	invert_zoom = bool(values.get("invert_zoom", invert_zoom))
	edge_pan_enabled = bool(values.get("edge_pan_enabled", edge_pan_enabled))
	auto_recenter_enabled = bool(values.get("auto_recenter_enabled", auto_recenter_enabled))
	auto_recenter_delay = float(values.get("auto_recenter_delay", auto_recenter_delay))
	auto_recenter_speed = float(values.get("auto_recenter_speed", auto_recenter_speed))
	fov_override_enabled = bool(values.get("fov_override_enabled", fov_override_enabled))
	preferred_fov_degrees = float(values.get("preferred_fov_degrees", preferred_fov_degrees))
	distance_override_enabled = bool(values.get("distance_override_enabled", distance_override_enabled))
	preferred_distance = float(values.get("preferred_distance", preferred_distance))
	motion_intensity = float(values.get("motion_intensity", motion_intensity))
	sanitize()
