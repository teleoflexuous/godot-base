extends CanvasLayer

signal transition_started(path: String)
signal transition_finished(path: String)

@export var default_duration: float = 0.25
@onready var fade_rect: ColorRect = $Fade


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	fade_rect.modulate.a = 0.0


func fade_out(duration: float = default_duration) -> void:
	await _fade_to(1.0, duration)


func fade_in(duration: float = default_duration) -> void:
	await _fade_to(0.0, duration)


func transition_to(scene_path: String, duration: float = default_duration) -> void:
	transition_started.emit(scene_path)
	await fade_out(duration)
	var result: Error = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		push_error("Could not change scene to %s" % scene_path)
	await get_tree().process_frame
	await fade_in(duration)
	transition_finished.emit(scene_path)


func _fade_to(alpha: float, duration: float) -> void:
	var tween: Tween = create_tween()
	var _pause_tween: Tween = tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var _property_tween: PropertyTweener = tween.tween_property(fade_rect, "modulate:a", clampf(alpha, 0.0, 1.0), maxf(duration, 0.0))
	await tween.finished
