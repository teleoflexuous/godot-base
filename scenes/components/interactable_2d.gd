class_name Interactable2D
extends Area2D

signal interacted(interactor: Node2D)

@export var prompt_text: String = "Interact"


func interact(interactor: Node2D) -> void:
	interacted.emit(interactor)
