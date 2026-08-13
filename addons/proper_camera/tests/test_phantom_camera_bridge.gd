extends GutTest


class Phantom2DDouble:
	extends Node

	var target: Node
	var follow_offset: Vector2 = Vector2.ZERO
	var zoom: Vector2 = Vector2.ONE

	func set_follow_target(value: Node) -> void:
		target = value

	func set_follow_offset(value: Vector2) -> void:
		follow_offset = value

	func set_zoom(value: Vector2) -> void:
		zoom = value


class Phantom3DDouble:
	extends Node3D

	signal became_active
	signal became_inactive

	var target: Node
	var follow_offset: Vector3 = Vector3.ZERO
	var third_person_rotation: Vector3 = Vector3.ZERO
	var spring_length: float = 0.0
	var projection: Camera3D.ProjectionType = Camera3D.PROJECTION_PERSPECTIVE
	var fov: float = 75.0
	var size: float = 10.0

	func set_follow_target(value: Node) -> void:
		target = value

	func set_follow_offset(value: Vector3) -> void:
		follow_offset = value

	func set_third_person_rotation_degrees(value: Vector3) -> void:
		third_person_rotation = value

	func set_spring_length(value: float) -> void:
		spring_length = value

	func set_projection(value: Camera3D.ProjectionType) -> void:
		projection = value

	func set_fov(value: float) -> void:
		fov = value

	func set_size(value: float) -> void:
		size = value


func test_bridge_recognizes_a_capability_complete_2d_double() -> void:
	var bridge: ProperCameraPhantomBridge = ProperCameraPhantomBridge.new()
	var phantom: Phantom2DDouble = Phantom2DDouble.new()
	bridge.add_child(phantom)
	bridge.bind_phantom_camera(phantom)
	add_child_autofree(bridge)
	assert_true(bridge.validate_bound_camera().is_empty())


func test_bridge_rejects_an_unrelated_node_without_hard_dependency() -> void:
	var bridge: ProperCameraPhantomBridge = ProperCameraPhantomBridge.new()
	var unrelated: Node = Node.new()
	bridge.add_child(unrelated)
	bridge.bind_phantom_camera(unrelated)
	add_child_autofree(bridge)
	assert_false(bridge.validate_bound_camera().is_empty())
	var source: String = FileAccess.get_file_as_string(
		"res://addons/proper_camera/runtime/integrations/phantom_camera_bridge.gd"
	)
	assert_false(source.contains("preload(\"res://addons/phantom_camera"))
	assert_false(source.contains("extends PhantomCamera"))


func test_3d_bridge_forwards_third_person_projection_and_active_state() -> void:
	var manager: Node = Node.new()
	manager.name = "PhantomCameraManager"
	get_tree().root.add_child(manager)
	autofree(manager)
	var bridge: ProperCameraPhantomBridge = ProperCameraPhantomBridge.new()
	var phantom: Phantom3DDouble = Phantom3DDouble.new()
	bridge.add_child(phantom)
	bridge.bind_phantom_camera(phantom)
	add_child_autofree(bridge)
	bridge.enabled = true
	var target: Node3D = Node3D.new()
	bridge.add_child(target)

	assert_true(bridge.apply_3d_third_person(target, Vector3(20.0, 35.0, 0.0), 6.5))
	assert_eq(phantom.target, target)
	assert_eq(phantom.third_person_rotation, Vector3(20.0, 35.0, 0.0))
	assert_true(is_equal_approx(phantom.spring_length, 6.5))
	assert_true(bridge.apply_projection(Camera3D.PROJECTION_PERSPECTIVE, 62.0, 8.0))
	assert_true(is_equal_approx(phantom.fov, 62.0))
	phantom.became_active.emit()
	assert_true(bridge.is_phantom_active())
	phantom.became_inactive.emit()
	assert_false(bridge.is_phantom_active())


func test_configuration_requires_a_registered_or_autoloaded_manager() -> void:
	var bridge: ProperCameraPhantomBridge = ProperCameraPhantomBridge.new()
	var phantom: Phantom2DDouble = Phantom2DDouble.new()
	bridge.add_child(phantom)
	bridge.bind_phantom_camera(phantom)
	add_child_autofree(bridge)
	assert_false(bridge.validate_configuration(false))
