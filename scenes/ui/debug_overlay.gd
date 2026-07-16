class_name DebugOverlay
extends CanvasLayer

signal skip_scene_requested()

@onready var label: Label = $Panel/Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _process(_delta: float) -> void:
	if visible:
		label.text = "DEBUG\nFPS: %d\nState: %s\nInvincible: %s" % [
			Engine.get_frames_per_second(),
			GameManager.GameState.keys()[GameManager.state],
			str(DevMode.is_enabled(&"invincible")),
		]


func _unhandled_input(event: InputEvent) -> void:
	if not DevMode.enabled or not event.is_action_pressed(&"debug_toggle_overlay"):
		return
	visible = not visible
	get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not DevMode.enabled:
		return
	if event.is_action_pressed(&"debug_skip_scene"):
		skip_scene_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"debug_toggle_invincibility"):
		DevMode.set_flag(&"invincible", not DevMode.is_enabled(&"invincible"))
		get_viewport().set_input_as_handled()
