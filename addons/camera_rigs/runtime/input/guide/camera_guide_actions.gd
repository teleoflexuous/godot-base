class_name CameraGuideActions
extends Resource

## Inject project-owned GUIDEAction resources here. The addon does not assume
## resource paths or create mappings inside the vendored GUIDE directory.
@export_group("Rates")
@export var pan_rate: GUIDEAction
@export var look_rate: GUIDEAction
@export var zoom_rate: GUIDEAction

@export_group("Device deltas")
@export var pan_delta: GUIDEAction
@export var touch_pan_delta: GUIDEAction
@export var look_delta: GUIDEAction
@export var pointer_position: GUIDEAction
@export var touch_pointer_position: GUIDEAction
@export var drag_pan: GUIDEAction
@export var drag_look: GUIDEAction

@export_group("Gestures")
@export var pinch_ratio: GUIDEAction
@export var twist_angle: GUIDEAction

@export_group("Discrete")
@export var zoom_step: GUIDEAction
@export var rotation_step: GUIDEAction
@export var fast_pan: GUIDEAction
@export var recenter: GUIDEAction
@export var follow_toggle: GUIDEAction
@export var view_toggle: GUIDEAction


func all_actions() -> Array[GUIDEAction]:
	var result: Array[GUIDEAction] = []
	for action: GUIDEAction in [
		pan_rate,
		look_rate,
		zoom_rate,
		pan_delta,
		touch_pan_delta,
		look_delta,
		pointer_position,
		touch_pointer_position,
		drag_pan,
		drag_look,
		pinch_ratio,
		twist_angle,
		zoom_step,
		rotation_step,
		fast_pan,
		recenter,
		follow_toggle,
		view_toggle,
	]:
		if action != null and not result.has(action):
			result.append(action)
	return result
