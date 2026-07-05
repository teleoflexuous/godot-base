extends RefCounted
class_name GraphicsQualityTiers

const LOW := &"low"
const BALANCED := &"balanced"
const HIGH := &"high"
const ALL := [LOW, BALANCED, HIGH]

static func is_valid_quality(value: StringName) -> bool:
	return ALL.has(value)
