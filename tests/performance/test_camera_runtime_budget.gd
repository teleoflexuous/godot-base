extends GutTest

const UPDATE_COUNT: int = 1000
const BUDGET_MICROSECONDS: int = 8000


func test_detail_band_updates_fit_one_gameplay_frame_budget() -> void:
	var near_band: ProperCameraDetailBand = ProperCameraDetailBand.new()
	near_band.id = &"near"
	var medium_band: ProperCameraDetailBand = ProperCameraDetailBand.new()
	medium_band.id = &"medium"
	medium_band.minimum_world_units_per_pixel = 0.05
	medium_band.hysteresis = 0.005
	var far_band: ProperCameraDetailBand = ProperCameraDetailBand.new()
	far_band.id = &"far"
	far_band.minimum_world_units_per_pixel = 0.12
	far_band.hysteresis = 0.01
	var profile: ProperCameraDetailProfile = ProperCameraDetailProfile.new()
	profile.bands = [near_band, medium_band, far_band]
	var coordinator: ProperCameraDetailCoordinator = ProperCameraDetailCoordinator.new()
	coordinator.profile = profile
	add_child_autofree(coordinator)
	var started: int = Time.get_ticks_usec()
	for index: int in range(UPDATE_COUNT):
		coordinator.update_metric(float(index % 200) / 1000.0)
	var elapsed: int = Time.get_ticks_usec() - started
	assert_lt(
		elapsed,
		BUDGET_MICROSECONDS,
		"%d detail updates should remain below the 8 ms gameplay-work budget." % UPDATE_COUNT
	)


func test_active_occlusion_search_is_statically_query_bounded() -> void:
	var source: String = FileAccess.get_file_as_string(
		"res://addons/proper_camera/runtime/rigs3d/camera_rig_3d.gd"
	)
	assert_true(source.contains("mini(preset.search_query_budget, candidates.size())"))
	assert_false(source.contains("get_tree().get_nodes_in_group"))
