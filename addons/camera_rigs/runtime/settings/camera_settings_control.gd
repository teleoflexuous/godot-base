class_name CameraSettingsControl
extends VBoxContainer

## Reference settings panel using built-in Controls. Assign the project-owned
## CameraSettings autoload (or a compatible service) and InputSettings service.

@export var camera_settings_service: Node
@export var input_settings_service: Node
@export var remapping_control: Control

const BUNDLE_IDS: Array[StringName] = [
	&"all",
	&"desktop",
	&"desktop_gamepad",
	&"mobile",
	&"gamepad",
	&"custom",
]
const BUNDLE_LABELS: Array[String] = [
	"All devices",
	"Desktop",
	"Desktop + gamepad",
	"Mobile + gamepad",
	"Gamepad only",
	"Custom",
]

var _bundle_option: OptionButton
var _horizontal_sensitivity: HSlider
var _vertical_sensitivity: HSlider
var _zoom_sensitivity: HSlider
var _invert_horizontal: CheckBox
var _invert_vertical: CheckBox
var _invert_zoom: CheckBox
var _edge_pan: CheckBox
var _auto_recenter: CheckBox
var _auto_recenter_delay: HSlider
var _auto_recenter_speed: HSlider
var _fov_override: CheckBox
var _preferred_fov: HSlider
var _distance_override: CheckBox
var _preferred_distance: HSlider
var _motion_intensity: HSlider


func _ready() -> void:
	_build_controls_if_needed()
	refresh()


func refresh() -> void:
	if is_instance_valid(input_settings_service):
		var bundle: StringName = StringName(input_settings_service.get(&"capability_bundle"))
		var bundle_index: int = BUNDLE_IDS.find(bundle)
		_bundle_option.select(maxi(bundle_index, 0))
	if not is_instance_valid(camera_settings_service) or not camera_settings_service.has_method(
		&"get_preferences"
	):
		return
	var preferences: CameraUserPreferences = camera_settings_service.call(&"get_preferences") as CameraUserPreferences
	if preferences == null:
		return
	_horizontal_sensitivity.value = preferences.horizontal_sensitivity
	_vertical_sensitivity.value = preferences.vertical_sensitivity
	_zoom_sensitivity.value = preferences.zoom_sensitivity
	_invert_horizontal.button_pressed = preferences.invert_horizontal
	_invert_vertical.button_pressed = preferences.invert_vertical
	_invert_zoom.button_pressed = preferences.invert_zoom
	_edge_pan.button_pressed = preferences.edge_pan_enabled
	_auto_recenter.button_pressed = preferences.auto_recenter_enabled
	_auto_recenter_delay.value = preferences.auto_recenter_delay
	_auto_recenter_speed.value = preferences.auto_recenter_speed
	_fov_override.button_pressed = preferences.fov_override_enabled
	_preferred_fov.value = preferences.preferred_fov_degrees
	_distance_override.button_pressed = preferences.distance_override_enabled
	_preferred_distance.value = preferences.preferred_distance
	_motion_intensity.value = preferences.motion_intensity


func _build_controls_if_needed() -> void:
	if get_child_count() > 0:
		_resolve_named_controls()
		return
	add_child(_make_label("Input devices"))
	_bundle_option = OptionButton.new()
	_bundle_option.name = "CapabilityBundle"
	for bundle_label: String in BUNDLE_LABELS:
		_bundle_option.add_item(bundle_label)
	add_child(_bundle_option)
	var bundle_result: Error = _bundle_option.item_selected.connect(_on_bundle_selected)
	if bundle_result != OK:
		push_warning("CameraSettingsControl could not connect its capability selector.")
	_horizontal_sensitivity = _add_slider("Horizontal sensitivity", 0.05, 5.0, 0.05)
	_vertical_sensitivity = _add_slider("Vertical sensitivity", 0.05, 5.0, 0.05)
	_zoom_sensitivity = _add_slider("Zoom sensitivity", 0.05, 5.0, 0.05)
	_motion_intensity = _add_slider("Camera motion intensity", 0.0, 1.0, 0.05)
	_invert_horizontal = _add_check_box("Invert horizontal look")
	_invert_vertical = _add_check_box("Invert vertical look")
	_invert_zoom = _add_check_box("Invert zoom")
	_edge_pan = _add_check_box("Enable edge pan")
	_auto_recenter = _add_check_box("Enable automatic recentering")
	_auto_recenter.name = "AutoRecenter"
	_auto_recenter_delay = _add_slider("Automatic recenter delay", 0.0, 30.0, 0.1)
	_auto_recenter_delay.name = "AutoRecenterDelay"
	_auto_recenter_speed = _add_slider("Automatic recenter speed", 0.0, 30.0, 0.1)
	_auto_recenter_speed.name = "AutoRecenterSpeed"
	_fov_override = _add_check_box("Allow FOV override")
	_fov_override.name = "FOVOverride"
	_preferred_fov = _add_slider("Preferred FOV", 1.0, 179.0, 1.0)
	_distance_override = _add_check_box("Allow distance override")
	_distance_override.name = "DistanceOverride"
	_preferred_distance = _add_slider("Preferred camera distance", 0.0, 100.0, 0.1)
	_preferred_distance.name = "PreferredDistance"
	var apply_button: Button = Button.new()
	apply_button.text = "Apply camera settings"
	add_child(apply_button)
	var apply_result: Error = apply_button.pressed.connect(apply)
	if apply_result != OK:
		push_warning("CameraSettingsControl could not connect its apply button.")
	var hint: Label = _make_label(
		"Touch camera gestures are fixed in G.U.I.D.E. v0.14. Keyboard, mouse, and gamepad bindings can be remapped below."
	)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	if remapping_control != null and remapping_control.get_parent() == null:
		add_child(remapping_control)


func apply() -> void:
	if not is_instance_valid(camera_settings_service) or not camera_settings_service.has_method(
		&"update_values"
	):
		return
	camera_settings_service.call(
		&"update_values",
		{
			"horizontal_sensitivity": _horizontal_sensitivity.value,
			"vertical_sensitivity": _vertical_sensitivity.value,
			"zoom_sensitivity": _zoom_sensitivity.value,
			"invert_horizontal": _invert_horizontal.button_pressed,
			"invert_vertical": _invert_vertical.button_pressed,
			"invert_zoom": _invert_zoom.button_pressed,
			"edge_pan_enabled": _edge_pan.button_pressed,
			"auto_recenter_enabled": _auto_recenter.button_pressed,
			"auto_recenter_delay": _auto_recenter_delay.value,
			"auto_recenter_speed": _auto_recenter_speed.value,
			"fov_override_enabled": _fov_override.button_pressed,
			"preferred_fov_degrees": _preferred_fov.value,
			"distance_override_enabled": _distance_override.button_pressed,
			"preferred_distance": _preferred_distance.value,
			"motion_intensity": _motion_intensity.value,
		}
	)


func _on_bundle_selected(index: int) -> void:
	if index < 0 or index >= BUNDLE_IDS.size():
		return
	var bundle: StringName = BUNDLE_IDS[index]
	if bundle == &"custom":
		return
	if is_instance_valid(input_settings_service) and input_settings_service.has_method(&"set_bundle"):
		input_settings_service.call(&"set_bundle", bundle)


func _resolve_named_controls() -> void:
	_bundle_option = get_node_or_null("CapabilityBundle") as OptionButton
	_horizontal_sensitivity = get_node_or_null("HorizontalSensitivity") as HSlider
	_vertical_sensitivity = get_node_or_null("VerticalSensitivity") as HSlider
	_zoom_sensitivity = get_node_or_null("ZoomSensitivity") as HSlider
	_motion_intensity = get_node_or_null("MotionIntensity") as HSlider
	_invert_horizontal = get_node_or_null("InvertHorizontal") as CheckBox
	_invert_vertical = get_node_or_null("InvertVertical") as CheckBox
	_invert_zoom = get_node_or_null("InvertZoom") as CheckBox
	_edge_pan = get_node_or_null("EdgePan") as CheckBox
	_auto_recenter = get_node_or_null("AutoRecenter") as CheckBox
	_auto_recenter_delay = get_node_or_null("AutoRecenterDelay") as HSlider
	_auto_recenter_speed = get_node_or_null("AutoRecenterSpeed") as HSlider
	_fov_override = get_node_or_null("FOVOverride") as CheckBox
	_preferred_fov = get_node_or_null("PreferredFOV") as HSlider
	_distance_override = get_node_or_null("DistanceOverride") as CheckBox
	_preferred_distance = get_node_or_null("PreferredDistance") as HSlider


func _add_slider(label_text: String, minimum: float, maximum: float, step: float) -> HSlider:
	add_child(_make_label(label_text))
	var slider: HSlider = HSlider.new()
	slider.name = StringName(label_text.replace(" ", "").replace("Camera", ""))
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	add_child(slider)
	return slider


func _add_check_box(label_text: String) -> CheckBox:
	var check_box: CheckBox = CheckBox.new()
	check_box.name = StringName(label_text.replace(" ", "").replace("Enable", "").replace("look", ""))
	check_box.text = label_text
	add_child(check_box)
	return check_box


func _make_label(text_value: String) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	return label
