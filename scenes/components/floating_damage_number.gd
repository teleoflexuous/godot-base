class_name FloatingDamageNumber
extends Label

@export var rise_distance: float = 36.0
@export var lifetime: float = 0.6


func show_damage(value: Variant, color: Color = Color.WHITE) -> void:
	text = str(value)
	modulate = color
	var start: Vector2 = position
	var tween: Tween = create_tween()
	var _parallel: Tween = tween.set_parallel(true)
	var _rise: PropertyTweener = tween.tween_property(self, "position:y", start.y - rise_distance, lifetime)
	var _fade: PropertyTweener = tween.tween_property(self, "modulate:a", 0.0, lifetime)
	var chained: Tween = tween.chain()
	var _remove: CallbackTweener = chained.tween_callback(queue_free)
