class_name ProperCameraPreset3D
extends Resource

@export_category("Follow")
@export var follow_enabled: bool = true
@export var follow_interruption: ProperCameraRigTypes.FollowInterruption = ProperCameraRigTypes.FollowInterruption.OFFSET_WHILE_FOLLOWING
@export_range(0.0, 40.0, 0.1) var follow_smoothing_speed: float = 10.0
@export var target_offset: Vector3 = Vector3(0.0, 1.5, 0.0)

@export_category("Movement")
@export var pan_enabled: bool = false
@export_range(0.0, 500.0, 0.1) var pan_speed: float = 18.0
@export var look_enabled: bool = true
@export_range(0.001, 10.0, 0.001) var look_sensitivity: float = 0.01
@export_range(-89.0, 89.0, 0.1) var min_pitch_degrees: float = -75.0
@export_range(-89.0, 89.0, 0.1) var max_pitch_degrees: float = -10.0
@export_range(-89.0, 89.0, 0.1) var starting_pitch_degrees: float = -25.0
@export_range(-360.0, 360.0, 0.1) var starting_yaw_degrees: float = 0.0
@export_range(0.0, 180.0, 0.1) var rotation_step_degrees: float = 15.0
@export var edge_scroll_enabled: bool = false
@export_range(0.0, 128.0, 1.0) var edge_scroll_margin: float = 24.0

@export_category("Zoom")
@export var zoom_enabled: bool = true
@export var zoom_mechanism: ProperCameraRigTypes.ZoomMechanism3D = ProperCameraRigTypes.ZoomMechanism3D.DOLLY
@export var zoom_anchor: ProperCameraRigTypes.ZoomAnchor = ProperCameraRigTypes.ZoomAnchor.FOLLOW_TARGET
@export_range(0.01, 500.0, 0.01) var min_distance: float = 0.05
@export_range(0.01, 1000.0, 0.01) var max_distance: float = 12.0
@export_range(1.0, 179.0, 0.1) var min_fov: float = 45.0
@export_range(1.0, 179.0, 0.1) var max_fov: float = 80.0
@export_range(0.01, 1000.0, 0.01) var min_orthographic_size: float = 4.0
@export_range(0.01, 2000.0, 0.01) var max_orthographic_size: float = 80.0
@export_range(0.001, 2.0, 0.001) var zoom_step_size: float = 0.08
@export_range(0.0, 40.0, 0.1) var zoom_smoothing_speed: float = 12.0
@export var pitch_policy: ProperCameraRigTypes.PitchPolicy = ProperCameraRigTypes.PitchPolicy.FIXED
@export var pitch_over_zoom: Curve
@export var pivot_height_over_zoom: Curve
@export var fov_over_zoom: Curve

@export_category("View")
@export var view_policy: ProperCameraRigTypes.ViewPolicy3D = ProperCameraRigTypes.ViewPolicy3D.THIRD_PERSON_ONLY
@export_range(0.0, 1.0, 0.001) var first_person_enter_zoom: float = 0.04
@export_range(0.0, 1.0, 0.001) var first_person_exit_zoom: float = 0.08
@export var first_person_offset: Vector3 = Vector3(0.0, 1.65, 0.0)

@export_category("Occlusion")
@export var occlusion_mode: ProperCameraRigTypes.OcclusionMode = ProperCameraRigTypes.OcclusionMode.PULL_IN
@export_flags_3d_physics var collision_mask: int = 1
@export_range(0.0, 2.0, 0.001) var collision_margin: float = 0.05
@export_range(0.0, 40.0, 0.1) var collision_recovery_speed: float = 8.0
@export_range(0.0, 2.0, 0.01) var search_delay: float = 0.25
@export_range(0, 16, 1) var search_query_budget: int = 5
@export_range(0.0, 90.0, 0.1) var search_max_yaw_degrees: float = 30.0
@export_range(0.0, 10.0, 0.01) var search_shoulder_distance: float = 0.75

@export_category("Bounds")
@export var bounds_enabled: bool = false
@export var bounds_min: Vector3 = Vector3(-100.0, -100.0, -100.0)
@export var bounds_max: Vector3 = Vector3(100.0, 100.0, 100.0)
@export var terrain_clearance_enabled: bool = false
@export_range(0.0, 100.0, 0.1) var minimum_terrain_clearance: float = 1.0
