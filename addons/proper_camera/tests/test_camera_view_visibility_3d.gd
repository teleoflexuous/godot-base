extends GutTest


func test_first_person_hide_mode_restores_visibility() -> void:
	var root: Node3D = Node3D.new()
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = "Body"
	visual.mesh = BoxMesh.new()
	root.add_child(visual)
	var visibility: ProperCameraViewVisibility3D = ProperCameraViewVisibility3D.new()
	visibility.visual_targets = [NodePath("../Body")]
	visibility.visibility_mode = ProperCameraViewVisibility3D.VisibilityMode.HIDE
	visibility.transition_speed = 100.0
	root.add_child(visibility)
	add_child_autofree(root)

	visibility.apply_view_mode(ProperCameraRigTypes.ViewMode3D.FIRST_PERSON)
	visibility._process(1.0)
	assert_false(visual.visible)
	visibility.apply_view_mode(ProperCameraRigTypes.ViewMode3D.THIRD_PERSON)
	visibility._process(1.0)
	assert_true(visual.visible)


func test_native_transparency_mode_restores_authored_value() -> void:
	var root: Node3D = Node3D.new()
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = "Body"
	visual.mesh = BoxMesh.new()
	visual.transparency = 0.25
	root.add_child(visual)
	var visibility: ProperCameraViewVisibility3D = ProperCameraViewVisibility3D.new()
	visibility.visual_targets = [NodePath("../Body")]
	visibility.visibility_mode = ProperCameraViewVisibility3D.VisibilityMode.NATIVE_TRANSPARENCY
	visibility.first_person_transparency = 0.9
	visibility.transition_speed = 100.0
	root.add_child(visibility)
	add_child_autofree(root)

	visibility.apply_view_mode(ProperCameraRigTypes.ViewMode3D.FIRST_PERSON)
	visibility._process(1.0)
	assert_true(is_equal_approx(visual.transparency, 0.9))
	visibility.restore_originals()
	assert_true(is_equal_approx(visual.transparency, 0.25))
