class_name ProperCameraPreset2D
extends Resource

@export_category("Follow")
@export var follow_enabled: bool = false
@export var follow_interruption: ProperCameraRigTypes.FollowInterruption = ProperCameraRigTypes.FollowInterruption.BREAK_ON_PAN
@export_range(0.0, 40.0, 0.1) var follow_smoothing_speed: float = 8.0
@export_range(0.0, 40.0, 0.1) var horizontal_follow_smoothing_speed: float = 0.0
@export_range(0.0, 40.0, 0.1) var vertical_follow_smoothing_speed: float = 0.0
@export var dead_zone: Vector2 = Vector2.ZERO
@export var look_ahead_distance: Vector2 = Vector2.ZERO
@export_range(0.0, 40.0, 0.1) var look_ahead_smoothing_speed: float = 6.0

@export_category("Movement")
@export var pan_enabled: bool = true
@export_range(0.0, 4000.0, 1.0) var pan_speed: float = 800.0
@export var look_enabled: bool = false
@export_range(0.0, 2000.0, 1.0) var peek_distance: float = 96.0
@export_range(0.0, 40.0, 0.1) var peek_smoothing_speed: float = 8.0
@export_range(0.0, 180.0, 0.1) var rotation_step_degrees: float = 15.0
@export var edge_scroll_enabled: bool = false
@export_range(0.0, 128.0, 1.0) var edge_scroll_margin: float = 24.0

@export_category("Zoom")
@export var zoom_enabled: bool = true
@export_range(0.01, 32.0, 0.01) var min_zoom: float = 0.5
@export_range(0.01, 32.0, 0.01) var max_zoom: float = 3.0
@export_range(0.001, 2.0, 0.001) var zoom_step_size: float = 0.12
@export_range(0.0, 40.0, 0.1) var zoom_smoothing_speed: float = 12.0
@export var zoom_anchor: ProperCameraRigTypes.ZoomAnchor = ProperCameraRigTypes.ZoomAnchor.POINTER_WORLD_HIT

@export_category("Bounds")
@export var bounds_enabled: bool = false
@export var bounds: Rect2 = Rect2(-2000.0, -2000.0, 4000.0, 4000.0)
@export var bounds_margin: Vector2 = Vector2.ZERO
