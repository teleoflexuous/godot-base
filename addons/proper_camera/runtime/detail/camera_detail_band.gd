class_name ProperCameraDetailBand
extends Resource

@export var id: StringName = &"near"
@export_range(0.0, 1000000.0, 0.0001, "or_greater") var minimum_world_units_per_pixel: float = 0.0
@export_range(0.0, 1000000.0, 0.0001, "or_greater") var hysteresis: float = 0.002
