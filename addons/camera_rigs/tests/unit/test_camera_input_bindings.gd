extends GutTest


func test_documented_keyboard_shortcuts_match_the_portable_input_map() -> void:
	assert_true(_action_has_physical_key(&"camera_recenter", KEY_R))
	assert_true(_action_has_physical_key(&"camera_follow_toggle", KEY_F))
	assert_true(_action_has_physical_key(&"camera_view_toggle", KEY_V))


func _action_has_physical_key(action: StringName, key: Key) -> bool:
	for input_event: InputEvent in InputMap.action_get_events(action):
		var key_event: InputEventKey = input_event as InputEventKey
		if key_event != null and key_event.physical_keycode == key:
			return true
	return false
