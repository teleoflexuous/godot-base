class_name JuiceTween
extends RefCounted

static func squash_stretch(node: CanvasItem, scale_amount: Vector2 = Vector2(1.15, 0.85), duration: float = 0.12) -> Tween:
	var raw_scale: Variant = node.get("scale")
	var original_scale: Vector2 = raw_scale if raw_scale is Vector2 else Vector2.ONE
	var tween: Tween = node.create_tween()
	var _transition: Tween = tween.set_trans(Tween.TRANS_QUAD)
	var _out_ease: Tween = tween.set_ease(Tween.EASE_OUT)
	var _stretch: PropertyTweener = tween.tween_property(node, "scale", original_scale * scale_amount, maxf(duration * 0.5, 0.01))
	var _in_ease: Tween = tween.set_ease(Tween.EASE_IN_OUT)
	var _restore: PropertyTweener = tween.tween_property(node, "scale", original_scale, maxf(duration * 0.5, 0.01))
	return tween
