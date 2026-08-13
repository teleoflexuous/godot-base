class_name ProperCameraRigTypes
extends RefCounted

enum FollowInterruption {
	HARD_LOCK,
	OFFSET_WHILE_FOLLOWING,
	BREAK_ON_PAN,
}

enum ZoomAnchor {
	VIEW_CENTER,
	FOLLOW_TARGET,
	SELECTION_TARGET,
	POINTER_WORLD_HIT,
	CUSTOM_PROVIDER,
}

enum ZoomMechanism3D {
	DOLLY,
	FOV,
	ORTHOGRAPHIC_SIZE,
	COMPOSITE,
}

enum PitchPolicy {
	FIXED,
	ZOOM_CURVE,
}

enum OcclusionMode {
	DISABLED,
	PULL_IN,
	PULL_IN_AND_SEARCH,
}

enum OutputDriver {
	NATIVE,
	PHANTOM,
}

enum ViewPolicy3D {
	THIRD_PERSON_ONLY,
	FIRST_PERSON_ONLY,
	TOGGLE,
	ZOOM_BLEND,
}

enum ViewMode3D {
	THIRD_PERSON,
	FIRST_PERSON,
}

enum DetailMetricSource {
	DESIRED,
	ACTUAL,
}
