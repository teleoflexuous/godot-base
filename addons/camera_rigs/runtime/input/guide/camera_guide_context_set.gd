class_name CameraGuideContextSet
extends Resource

## Values intentionally match InputCapabilities without coupling the addon to a
## project script. Multiple device contexts can be active simultaneously.
const KEYBOARD: int = 1
const MOUSE: int = 2
const GAMEPAD: int = 4
const TOUCH: int = 8

@export var shared_contexts: Array[GUIDEMappingContext] = []
@export var keyboard_contexts: Array[GUIDEMappingContext] = []
@export var mouse_contexts: Array[GUIDEMappingContext] = []
@export var gamepad_contexts: Array[GUIDEMappingContext] = []
@export var touch_contexts: Array[GUIDEMappingContext] = []


func contexts_for_mask(mask: int) -> Array[GUIDEMappingContext]:
	var result: Array[GUIDEMappingContext] = []
	_append_unique(result, shared_contexts)
	if mask & KEYBOARD:
		_append_unique(result, keyboard_contexts)
	if mask & MOUSE:
		_append_unique(result, mouse_contexts)
	if mask & GAMEPAD:
		_append_unique(result, gamepad_contexts)
	if mask & TOUCH:
		_append_unique(result, touch_contexts)
	return result


func all_contexts() -> Array[GUIDEMappingContext]:
	var result: Array[GUIDEMappingContext] = []
	_append_unique(result, shared_contexts)
	_append_unique(result, keyboard_contexts)
	_append_unique(result, mouse_contexts)
	_append_unique(result, gamepad_contexts)
	_append_unique(result, touch_contexts)
	return result


func _append_unique(target: Array[GUIDEMappingContext], source: Array[GUIDEMappingContext]) -> void:
	for context: GUIDEMappingContext in source:
		if context != null and not target.has(context):
			target.append(context)
