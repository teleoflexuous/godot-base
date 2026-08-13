class_name ProperCameraInputMapActions
extends Resource

@export_group("Rates")
@export var pan_left: StringName = &"camera_pan_left"
@export var pan_right: StringName = &"camera_pan_right"
@export var pan_up: StringName = &"camera_pan_up"
@export var pan_down: StringName = &"camera_pan_down"
@export var look_left: StringName = &"camera_look_left"
@export var look_right: StringName = &"camera_look_right"
@export var look_up: StringName = &"camera_look_up"
@export var look_down: StringName = &"camera_look_down"
@export var zoom_in_rate: StringName = &"camera_zoom_in"
@export var zoom_out_rate: StringName = &"camera_zoom_out"

@export_group("Pointer")
@export var pan_drag: StringName = &"camera_pan_drag"
@export var look_drag: StringName = &"camera_look_drag"
@export var fast_pan: StringName = &"camera_fast_pan"

@export_group("Steps")
@export var zoom_in_step: StringName = &"camera_zoom_in_step"
@export var zoom_out_step: StringName = &"camera_zoom_out_step"
@export var recenter: StringName = &"camera_recenter"
@export var follow_toggle: StringName = &"camera_follow_toggle"
@export var view_toggle: StringName = &"camera_view_toggle"
@export var rotate_left: StringName = &"camera_rotate_left"
@export var rotate_right: StringName = &"camera_rotate_right"
