extends GutTest


func test_2d_native_fade_is_reference_counted_and_restorable() -> void:
	var root: Node2D = Node2D.new()
	var visual: Node2D = Node2D.new()
	visual.name = "Visual"
	visual.self_modulate = Color(0.5, 0.75, 1.0, 0.8)
	root.add_child(visual)
	var occluder: ProperCameraOccluder2D = ProperCameraOccluder2D.new()
	occluder.visual_targets = [NodePath("../Visual")]
	occluder.fade_mode = ProperCameraFadeTypes.FadeMode.NATIVE
	occluder.fade_in_speed = 100.0
	occluder.fade_out_speed = 100.0
	root.add_child(occluder)
	add_child_autofree(root)
	occluder.request_fade(1, 1.0)
	occluder.request_fade(2, 0.5)
	occluder._process(1.0)
	assert_lt(visual.self_modulate.a, 0.8)
	occluder.clear_fade(1)
	occluder._process(1.0)
	assert_true(is_equal_approx(occluder.get_fade_amount(), 0.5))
	occluder.clear_fade(2)
	occluder._process(1.0)
	assert_true(is_equal_approx(visual.self_modulate.a, 0.8))


func test_3d_native_fade_restores_original_transparency() -> void:
	var root: Node3D = Node3D.new()
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = "Visual"
	visual.transparency = 0.2
	root.add_child(visual)
	var occluder: ProperCameraOccluder3D = ProperCameraOccluder3D.new()
	occluder.visual_targets = [NodePath("../Visual")]
	occluder.fade_mode = ProperCameraFadeTypes.FadeMode.NATIVE
	occluder.fade_in_speed = 100.0
	occluder.fade_out_speed = 100.0
	root.add_child(occluder)
	add_child_autofree(root)
	occluder.request_fade(1)
	occluder._process(1.0)
	assert_true(visual.transparency > 0.2)
	occluder.clear_fade(1)
	occluder._process(1.0)
	assert_true(is_equal_approx(visual.transparency, 0.2))


func test_2d_instance_shader_fade_is_detected_and_restored() -> void:
	var root: Node2D = Node2D.new()
	var visual: Polygon2D = Polygon2D.new()
	visual.name = "Visual"
	visual.polygon = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN])
	var shader: Shader = Shader.new()
	shader.code = (
		"shader_type canvas_item;\n"
		+ "instance uniform float camera_fade = 0.0;\n"
		+ "void fragment() { COLOR.a *= 1.0 - camera_fade; }\n"
	)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	visual.material = material
	root.add_child(visual)
	var occluder: ProperCameraOccluder2D = ProperCameraOccluder2D.new()
	occluder.visual_targets = [NodePath("../Visual")]
	occluder.fade_mode = ProperCameraFadeTypes.FadeMode.INSTANCE_SHADER_PARAMETER
	occluder.fade_in_speed = 100.0
	occluder.fade_out_speed = 100.0
	root.add_child(occluder)
	add_child_autofree(root)
	assert_true(occluder.validate_configuration().is_empty())
	occluder.request_fade(1)
	occluder._process(1.0)
	assert_true(is_equal_approx(float(visual.get_instance_shader_parameter(&"camera_fade")), 1.0))
	occluder.clear_fade(1)
	occluder._process(1.0)
	assert_true(is_zero_approx(float(visual.get_instance_shader_parameter(&"camera_fade"))))


func test_3d_instance_shader_fade_is_detected_and_restored() -> void:
	var root: Node3D = Node3D.new()
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = "Visual"
	visual.mesh = BoxMesh.new()
	var shader: Shader = Shader.new()
	shader.code = (
		"shader_type spatial;\n"
		+ "instance uniform float camera_fade = 0.0;\n"
		+ "void fragment() { ALBEDO = vec3(1.0); ALPHA = 1.0 - camera_fade; }\n"
	)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	visual.material_override = material
	root.add_child(visual)
	var occluder: ProperCameraOccluder3D = ProperCameraOccluder3D.new()
	occluder.visual_targets = [NodePath("../Visual")]
	occluder.fade_mode = ProperCameraFadeTypes.FadeMode.INSTANCE_SHADER_PARAMETER
	occluder.fade_in_speed = 100.0
	occluder.fade_out_speed = 100.0
	root.add_child(occluder)
	add_child_autofree(root)
	assert_true(occluder.validate_configuration().is_empty())
	occluder.request_fade(1)
	occluder._process(1.0)
	assert_true(is_equal_approx(float(visual.get_instance_shader_parameter(&"camera_fade")), 1.0))
	occluder.clear_fade(1)
	occluder._process(1.0)
	assert_true(is_zero_approx(float(visual.get_instance_shader_parameter(&"camera_fade"))))
