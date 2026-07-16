extends RefCounted
class_name GraphicsQualityTiers

const LOW: StringName = &"low"
const BALANCED: StringName = &"balanced"
const HIGH: StringName = &"high"
const ALL: Array[StringName] = [LOW, BALANCED, HIGH]

static func is_valid_quality(value: StringName) -> bool:
	return ALL.has(value)
