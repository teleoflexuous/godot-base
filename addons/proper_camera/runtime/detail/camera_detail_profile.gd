class_name ProperCameraDetailProfile
extends Resource

@export var bands: Array[ProperCameraDetailBand] = []


func get_band_index(metric: float) -> int:
	if bands.is_empty():
		return -1
	var selected_index: int = 0
	for index: int in range(bands.size()):
		var band: ProperCameraDetailBand = bands[index]
		if band != null and metric >= band.minimum_world_units_per_pixel:
			selected_index = index
	return selected_index


func get_hysteretic_band_index(metric: float, current_index: int) -> int:
	var candidate_index: int = get_band_index(metric)
	if candidate_index < 0 or current_index < 0 or current_index >= bands.size():
		return candidate_index
	if candidate_index > current_index:
		var entering_band: ProperCameraDetailBand = bands[candidate_index]
		if entering_band != null and metric < entering_band.minimum_world_units_per_pixel + entering_band.hysteresis:
			return current_index
	elif candidate_index < current_index:
		var current_band: ProperCameraDetailBand = bands[current_index]
		if current_band != null and metric > current_band.minimum_world_units_per_pixel - current_band.hysteresis:
			return current_index
	return candidate_index


func get_band_id(index: int) -> StringName:
	if index < 0 or index >= bands.size() or bands[index] == null:
		return &""
	return bands[index].id
