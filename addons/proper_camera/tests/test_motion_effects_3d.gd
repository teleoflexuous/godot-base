extends GutTest


func test_impulse_samples_are_deterministic() -> void:
	var first := ProperCameraMotionEffects3D.new()
	var second := ProperCameraMotionEffects3D.new()
	first.deterministic_seed = 42
	second.deterministic_seed = 42
	first.add_impulse(Vector3(1.0, 2.0, 3.0), Vector3(0.1, 0.2, 0.3), 2.0, 0.5, 8.0)
	second.add_impulse(Vector3(1.0, 2.0, 3.0), Vector3(0.1, 0.2, 0.3), 2.0, 0.5, 8.0)
	first.advance(0.125)
	second.advance(0.125)
	var first_sample: Dictionary = first.get_motion_sample()
	var second_sample: Dictionary = second.get_motion_sample()
	assert_true(Vector3(first_sample["translation"]).is_equal_approx(Vector3(second_sample["translation"])))
	assert_true(Vector3(first_sample["rotation"]).is_equal_approx(Vector3(second_sample["rotation"])))
	assert_almost_eq(float(first_sample["fov_offset"]), float(second_sample["fov_offset"]), 0.0001)
	first.free()
	second.free()


func test_impulse_finishes_and_cancel_restores_zero_sample() -> void:
	var effects := ProperCameraMotionEffects3D.new()
	effects.add_impulse(Vector3.ONE, Vector3.ONE, 1.0, 0.1, 10.0)
	effects.advance(0.2)
	assert_false(effects.has_active_effects())
	var sample: Dictionary = effects.get_motion_sample()
	assert_eq(sample["translation"], Vector3.ZERO)
	effects.start_noise(Vector3.ONE, Vector3.ONE, 1.0, 2.0, 9)
	effects.advance(0.1)
	assert_true(effects.has_active_effects())
	effects.cancel_all()
	assert_false(effects.has_active_effects())
	assert_eq(effects.get_motion_sample()["translation"], Vector3.ZERO)
	effects.free()


func test_zero_motion_intensity_suppresses_noise_channels() -> void:
	var effects := ProperCameraMotionEffects3D.new()
	effects.motion_intensity = 0.0
	effects.start_noise(Vector3.ONE * 10.0, Vector3.ONE, 5.0, 3.0, 11)
	effects.advance(0.25)
	var sample: Dictionary = effects.get_motion_sample()
	assert_eq(sample["translation"], Vector3.ZERO)
	assert_eq(sample["rotation"], Vector3.ZERO)
	assert_eq(sample["fov_offset"], 0.0)
	effects.free()
