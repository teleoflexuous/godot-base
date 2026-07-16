extends GutTest

func test_game_root_loads() -> void:
	var packed_scene: PackedScene = load("res://scenes/game/game_root.tscn")
	assert_not_null(packed_scene)
	var scene := packed_scene.instantiate()
	add_child_autofree(scene)
	assert_not_null(scene.get_node_or_null("MainMenu/Title"))


func test_2d_starter_scenes_load() -> void:
	for path: String in ["res://scenes/characters/top_down_character_2d.tscn", "res://scenes/characters/platformer_character_2d.tscn", "res://scenes/components/interactable_2d.tscn"]:
		var packed_scene: PackedScene = load(path)
		assert_not_null(packed_scene, "Expected starter scene to load: %s" % path)


func test_example_2d_scene_loads() -> void:
	var packed_scene: PackedScene = load("res://scenes/examples/2d/example_2d_scene.tscn")
	assert_not_null(packed_scene)
	var scene := packed_scene.instantiate()
	add_child_autofree(scene)
	assert_not_null(scene.get_node_or_null("Camera2D"))
	assert_not_null(scene.get_node_or_null("Ground/CollisionShape2D"))


func test_example_3d_scene_loads() -> void:
	var packed_scene: PackedScene = load("res://scenes/examples/3d/example_3d_scene.tscn")
	assert_not_null(packed_scene)
	var scene := packed_scene.instantiate()
	add_child_autofree(scene)
	assert_not_null(scene.get_node_or_null("WorldEnvironment"))
	assert_not_null(scene.get_node_or_null("Sun"))
	assert_not_null(scene.get_node_or_null("Camera3D"))
	assert_not_null(scene.get_node_or_null("Floor/CollisionShape3D"))
