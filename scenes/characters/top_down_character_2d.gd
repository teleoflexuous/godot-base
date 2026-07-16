class_name TopDownCharacter2D
extends CharacterBody2D

@export var speed: float = 220.0


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = direction * speed
	var _collided: bool = move_and_slide()
