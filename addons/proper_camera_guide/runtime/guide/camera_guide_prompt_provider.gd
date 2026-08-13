class_name ProperCameraGuidePromptProvider
extends Node

signal prompts_changed()

@export var context_set: ProperCameraGuideContextSet
@export_flags("Keyboard", "Mouse", "Gamepad", "Touch") var device_mask: int = 15
@export_range(8, 128, 1) var icon_size: int = 32


func _ready() -> void:
	var guide: Node = get_node_or_null(NodePath("/root/GUIDE"))
	if guide != null:
		guide.connect("input_mappings_changed", _on_input_mappings_changed)


func _exit_tree() -> void:
	var guide: Node = get_node_or_null(NodePath("/root/GUIDE"))
	if guide != null and guide.is_connected("input_mappings_changed", _on_input_mappings_changed):
		guide.disconnect("input_mappings_changed", _on_input_mappings_changed)


func action_as_text(action: GUIDEAction, active_contexts_only: bool = true) -> String:
	var formatter: GUIDEInputFormatter
	if active_contexts_only or context_set == null:
		formatter = GUIDEInputFormatter.for_active_contexts(icon_size)
	else:
		formatter = GUIDEInputFormatter.for_contexts(context_set.contexts_for_mask(device_mask), icon_size)
	return formatter.action_as_text(action)


func action_as_richtext(action: GUIDEAction, active_contexts_only: bool = true) -> String:
	var formatter: GUIDEInputFormatter
	if active_contexts_only or context_set == null:
		formatter = GUIDEInputFormatter.for_active_contexts(icon_size)
	else:
		formatter = GUIDEInputFormatter.for_contexts(context_set.contexts_for_mask(device_mask), icon_size)
	return await formatter.action_as_richtext_async(action)


func _on_input_mappings_changed() -> void:
	prompts_changed.emit()
