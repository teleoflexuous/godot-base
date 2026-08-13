extends GutTest


func test_detail_profile_uses_hysteresis_in_both_directions() -> void:
	var near_band: ProperCameraDetailBand = ProperCameraDetailBand.new()
	near_band.id = &"near"
	near_band.minimum_world_units_per_pixel = 0.0
	var medium_band: ProperCameraDetailBand = ProperCameraDetailBand.new()
	medium_band.id = &"medium"
	medium_band.minimum_world_units_per_pixel = 0.05
	medium_band.hysteresis = 0.01
	var far_band: ProperCameraDetailBand = ProperCameraDetailBand.new()
	far_band.id = &"far"
	far_band.minimum_world_units_per_pixel = 0.1
	far_band.hysteresis = 0.02
	var profile: ProperCameraDetailProfile = ProperCameraDetailProfile.new()
	profile.bands = [near_band, medium_band, far_band]
	assert_eq(profile.get_hysteretic_band_index(0.11, 1), 1)
	assert_eq(profile.get_hysteretic_band_index(0.13, 1), 2)
	assert_eq(profile.get_hysteretic_band_index(0.09, 2), 2)
	assert_eq(profile.get_hysteretic_band_index(0.07, 2), 1)


func test_property_mapper_applies_band_value_and_restores_original() -> void:
	var root: Node = Node.new()
	var target: Node = Node.new()
	target.name = "Target"
	target.process_priority = 3
	root.add_child(target)
	var near_band: ProperCameraDetailBand = ProperCameraDetailBand.new()
	near_band.id = &"near"
	var far_band: ProperCameraDetailBand = ProperCameraDetailBand.new()
	far_band.id = &"far"
	far_band.minimum_world_units_per_pixel = 0.1
	var profile: ProperCameraDetailProfile = ProperCameraDetailProfile.new()
	profile.bands = [near_band, far_band]
	var coordinator: ProperCameraDetailCoordinator = ProperCameraDetailCoordinator.new()
	coordinator.name = "Coordinator"
	coordinator.profile = profile
	root.add_child(coordinator)
	var binding: ProperCameraDetailPropertyBinding = ProperCameraDetailPropertyBinding.new()
	binding.target_path = NodePath("../Target")
	binding.property_name = &"process_priority"
	binding.values_by_band = {&"near": 4, &"far": 12}
	var mapper: ProperCameraDetailPropertyMapper = ProperCameraDetailPropertyMapper.new()
	mapper.coordinator_path = NodePath("../Coordinator")
	mapper.bindings = [binding]
	root.add_child(mapper)
	add_child_autofree(root)
	coordinator.update_metric(0.2)
	assert_eq(target.process_priority, 12)
	mapper.restore_originals()
	assert_eq(target.process_priority, 3)
