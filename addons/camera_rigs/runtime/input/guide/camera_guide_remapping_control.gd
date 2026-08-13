class_name CameraGuideRemappingControl
extends VBoxContainer

@export var controller: CameraGuideRemappingController
@export var show_fixed_touch_note: bool = true

var _collision_dialog: ConfirmationDialog


func _ready() -> void:
	if controller == null:
		return
	controller.configuration_changed.connect(_rebuild)
	controller.detection_finished.connect(_on_detection_finished)
	controller.collision_resolution_requested.connect(_on_collision_requested)
	_collision_dialog = ConfirmationDialog.new()
	_collision_dialog.title = "Binding already in use"
	_collision_dialog.ok_button_text = "Replace"
	_collision_dialog.add_button("Swap", true, "swap")
	_collision_dialog.confirmed.connect(_resolve_replace)
	_collision_dialog.canceled.connect(_resolve_cancel)
	_collision_dialog.custom_action.connect(_on_collision_custom_action)
	add_child(_collision_dialog)
	_rebuild()


func _rebuild() -> void:
	for child: Node in get_children():
		if child != _collision_dialog:
			remove_child(child)
			child.queue_free()
	var formatter: GUIDEInputFormatter = GUIDEInputFormatter.for_active_contexts()
	for item: Variant in controller.get_remappable_items():
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = "%s — %s" % [item.display_category, item.display_name]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var binding_button: Button = Button.new()
		var bound_input: GUIDEInput = controller.get_bound_input_or_null(item)
		binding_button.text = formatter.input_as_text(bound_input) if bound_input != null else "Unbound"
		binding_button.pressed.connect(_begin_item_detection.bind(item))
		row.add_child(binding_button)
		var reset_button: Button = Button.new()
		reset_button.text = "Reset"
		reset_button.pressed.connect(_reset_item.bind(item))
		row.add_child(reset_button)
		add_child(row)
	if show_fixed_touch_note:
		var note: Label = Label.new()
		note.text = "Touch gestures are fixed: G.U.I.D.E. v0.14 does not detect touch remaps."
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(note)
	move_child(_collision_dialog, get_child_count() - 1)


func _begin_item_detection(item: Variant) -> void:
	controller.begin_detection(item)


func _reset_item(item: Variant) -> void:
	controller.restore_default(item)
	controller.apply_configuration()


func _on_detection_finished(_item: Variant, input: GUIDEInput) -> void:
	if input != null:
		_rebuild()


func _on_collision_requested(_item: Variant, _input: GUIDEInput, collisions: Array) -> void:
	_collision_dialog.dialog_text = (
		"This binding conflicts with %d existing binding(s). Replace them, swap when there is one, or cancel."
		% collisions.size()
	)
	_collision_dialog.popup_centered()


func _resolve_replace() -> void:
	controller.resolve_collision(CameraGuideRemappingController.CollisionResolution.REPLACE)
	controller.apply_configuration()


func _resolve_cancel() -> void:
	controller.resolve_collision(CameraGuideRemappingController.CollisionResolution.CANCEL)


func _on_collision_custom_action(action: StringName) -> void:
	if action == &"swap":
		controller.resolve_collision(CameraGuideRemappingController.CollisionResolution.SWAP)
		controller.apply_configuration()
	_collision_dialog.hide()
