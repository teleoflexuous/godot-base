extends Control

signal example_requested(example_path: String)

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel

func _ready() -> void:
	title_label.text = ProjectSettings.get_setting("application/config/name", "Godot Base")
	description_label.text = "Reusable Godot scaffold. Example scenes live under scenes/examples/."
	if has_node("/root/DebugLog"):
		DebugLog.info("Game root ready")


func request_example(example_path: String) -> void:
	example_requested.emit(example_path)
