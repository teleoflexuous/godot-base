extends GutTest


func test_impulse_is_deterministic_and_restores_the_owned_base() -> void:
	var holder := Node2D.new()
	var pivot := Node2D.new()
	pivot.name = "EffectPivot"
	pivot.position = Vector2(20.0, 30.0)
	holder.add_child(pivot)
	var effects := ProperCameraMotionEffects2D.new()
	effects.target_pivot_path = ^"../EffectPivot"
	holder.add_child(effects)
	add_child_autofree(holder)
	await get_tree().process_frame

	effects.add_impulse(Vector2(12.0, 8.0), 0.1, 0.5, 9.0, 42)
	effects._process(0.025)
	var first_sample: Vector2 = effects.get_current_translation()
	assert_false(first_sample.is_zero_approx())
	effects.cancel_all()
	assert_eq(pivot.position, Vector2(20.0, 30.0))

	effects.add_impulse(Vector2(12.0, 8.0), 0.1, 0.5, 9.0, 42)
	effects._process(0.025)
	assert_almost_eq(effects.get_current_translation().x, first_sample.x, 0.0001)
	assert_almost_eq(effects.get_current_translation().y, first_sample.y, 0.0001)


func test_external_base_edits_are_preserved_when_motion_is_cancelled() -> void:
	var holder := Node2D.new()
	var pivot := Node2D.new()
	pivot.name = "EffectPivot"
	pivot.position = Vector2(4.0, 7.0)
	holder.add_child(pivot)
	var effects := ProperCameraMotionEffects2D.new()
	effects.target_pivot_path = ^"../EffectPivot"
	holder.add_child(effects)
	add_child_autofree(holder)
	await get_tree().process_frame

	effects.start_noise(&"wind", Vector2(5.0, 3.0), 0.05, 2.0, 7)
	effects._process(0.1)
	pivot.position += Vector2(11.0, -2.0)
	effects.cancel_all()
	assert_almost_eq(pivot.position.x, 15.0, 0.0001)
	assert_almost_eq(pivot.position.y, 5.0, 0.0001)


func test_motion_intensity_zero_keeps_the_base_transform() -> void:
	var holder := Node2D.new()
	var pivot := Node2D.new()
	pivot.name = "EffectPivot"
	pivot.position = Vector2(9.0, 13.0)
	holder.add_child(pivot)
	var effects := ProperCameraMotionEffects2D.new()
	effects.target_pivot_path = ^"../EffectPivot"
	effects.motion_intensity = 0.0
	holder.add_child(effects)
	add_child_autofree(holder)
	await get_tree().process_frame

	effects.start_noise(&"idle", Vector2(50.0, 50.0), 0.5, 5.0, 3)
	effects._process(0.2)
	assert_eq(pivot.position, Vector2(9.0, 13.0))
	assert_eq(pivot.rotation, 0.0)
