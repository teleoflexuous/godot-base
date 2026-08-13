class_name CameraGuideDefaults
extends Resource

@export var actions: CameraGuideActions
@export var context_set: CameraGuideContextSet
@export var keyboard_context: GUIDEMappingContext
@export var mouse_context: GUIDEMappingContext
@export var gamepad_context: GUIDEMappingContext
@export var touch_context: GUIDEMappingContext


func all_contexts() -> Array[GUIDEMappingContext]:
	return context_set.all_contexts() if context_set != null else []
