extends GutTest


func test_detail_profile_uses_hysteresis_in_both_directions() -> void:
	var near_band: CameraDetailBand = CameraDetailBand.new()
	near_band.id = &"near"
	near_band.minimum_world_units_per_pixel = 0.0
	var medium_band: CameraDetailBand = CameraDetailBand.new()
	medium_band.id = &"medium"
	medium_band.minimum_world_units_per_pixel = 0.05
	medium_band.hysteresis = 0.01
	var far_band: CameraDetailBand = CameraDetailBand.new()
	far_band.id = &"far"
	far_band.minimum_world_units_per_pixel = 0.1
	far_band.hysteresis = 0.02
	var profile: CameraDetailProfile = CameraDetailProfile.new()
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
	var near_band: CameraDetailBand = CameraDetailBand.new()
	near_band.id = &"near"
	var far_band: CameraDetailBand = CameraDetailBand.new()
	far_band.id = &"far"
	far_band.minimum_world_units_per_pixel = 0.1
	var profile: CameraDetailProfile = CameraDetailProfile.new()
	profile.bands = [near_band, far_band]
	var coordinator: CameraDetailCoordinator = CameraDetailCoordinator.new()
	coordinator.name = "Coordinator"
	coordinator.profile = profile
	root.add_child(coordinator)
	var binding: CameraDetailPropertyBinding = CameraDetailPropertyBinding.new()
	binding.target_path = NodePath("../Target")
	binding.property_name = &"process_priority"
	binding.values_by_band = {&"near": 4, &"far": 12}
	var mapper: CameraDetailPropertyMapper = CameraDetailPropertyMapper.new()
	mapper.coordinator_path = NodePath("../Coordinator")
	mapper.bindings = [binding]
	root.add_child(mapper)
	add_child_autofree(root)
	coordinator.update_metric(0.2)
	assert_eq(target.process_priority, 12)
	mapper.restore_originals()
	assert_eq(target.process_priority, 3)
