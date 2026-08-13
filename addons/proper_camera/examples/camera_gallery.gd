extends Control

const EXAMPLES: Array[Dictionary] = [
	{"name": "2D management", "path": "res://addons/proper_camera/examples/2d_management.tscn"},
	{"name": "2D platformer", "path": "res://addons/proper_camera/examples/2d_platformer.tscn"},
	{"name": "3D character", "path": "res://addons/proper_camera/examples/3d_character.tscn"},
	{"name": "3D management", "path": "res://addons/proper_camera/examples/3d_management.tscn"},
	{"name": "3D RTS / MOBA", "path": "res://addons/proper_camera/examples/3d_rts_moba.tscn"},
	{"name": "Occlusion stability lab", "path": "res://addons/proper_camera/examples/occlusion_stability_lab.tscn"},
]


func _ready() -> void:
	var list: VBoxContainer = %ExampleList
	for example: Dictionary in EXAMPLES:
		var button: Button = Button.new()
		button.text = str(example["name"])
		var path: String = str(example["path"])
		var result: Error = button.pressed.connect(_open_example.bind(path))
		if result != OK:
			push_warning("Camera gallery could not connect an example button.")
		list.add_child(button)


func _open_example(path: String) -> void:
	var result: Error = get_tree().change_scene_to_file(path)
	if result != OK:
		push_error("Could not open camera example: %s" % path)
