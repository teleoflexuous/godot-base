extends Node2D

@export var rig_path: NodePath = ^"ProperCameraRig2D"
@export var adapter_path: NodePath = ^"ProperCameraInputMapAdapter"
@export var target_path: NodePath
@export var platformer_mode: bool = false
@export var title: String = "2D Camera"
@export_file("*.tscn") var gallery_scene_path: String = "res://addons/proper_camera/examples/camera_gallery.tscn"

var _rig: ProperCameraRig2D
var _target: Node2D


func _ready() -> void:
	_rig = get_node_or_null(rig_path) as ProperCameraRig2D
	var adapter: ProperCameraInputMapAdapter = get_node_or_null(adapter_path) as ProperCameraInputMapAdapter
	if adapter != null:
		adapter.camera_rig = _rig
	_target = get_node_or_null(target_path) as Node2D
	if _rig != null and _target != null:
		_rig.set_follow_target(_target, true)
		_rig.set_following(_rig.preset.follow_enabled, true)
	var back_button: Button = get_node_or_null("UI/Back") as Button
	if back_button != null:
		var result: Error = back_button.pressed.connect(return_to_gallery)
		if result != OK:
			push_warning("Camera example could not connect its gallery back button.")
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		return_to_gallery()
		get_viewport().set_input_as_handled()


func return_to_gallery() -> void:
	var result: Error = get_tree().change_scene_to_file(gallery_scene_path)
	if result != OK:
		push_error("Could not return to the camera gallery: %s" % gallery_scene_path)


func _physics_process(delta: float) -> void:
	if not platformer_mode or _target == null:
		return
	var direction: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_target.position += direction * 240.0 * delta


func _draw() -> void:
	for x: int in range(-2000, 2001, 100):
		draw_line(Vector2(x, -1200), Vector2(x, 1200), Color(0.16, 0.22, 0.3), 1.0)
	for y: int in range(-1200, 1201, 100):
		draw_line(Vector2(-2000, y), Vector2(2000, y), Color(0.16, 0.22, 0.3), 1.0)
