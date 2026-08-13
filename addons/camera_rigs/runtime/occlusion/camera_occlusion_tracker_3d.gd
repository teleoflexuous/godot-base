class_name CameraOcclusionTracker3D
extends Node3D

signal occluders_changed(occluders: Array[CameraOccluder3D])

@export var focus_path: NodePath
@export var camera_path: NodePath
@export_flags_3d_physics var collision_mask: int = 1
@export_range(1, 32, 1) var maximum_hits: int = 8
@export var excluded_collision_paths: Array[NodePath] = []

var _active: Array[CameraOccluder3D] = []


func _physics_process(_delta: float) -> void:
	var focus: Node3D = get_node_or_null(focus_path) as Node3D
	var camera: Node3D = get_node_or_null(camera_path) as Node3D
	if focus == null or camera == null or not is_inside_tree():
		_set_active([])
		return
	var exclude: Array[RID] = []
	for path: NodePath in excluded_collision_paths:
		var object: CollisionObject3D = get_node_or_null(path) as CollisionObject3D
		if object != null:
			exclude.append(object.get_rid())
	var found: Array[CameraOccluder3D] = []
	for _query_index: int in range(maximum_hits):
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			focus.global_position,
			camera.global_position,
			collision_mask,
			exclude
		)
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			break
		var collider: CollisionObject3D = hit.get(&"collider") as CollisionObject3D
		if collider == null:
			break
		exclude.append(collider.get_rid())
		var occluder: CameraOccluder3D = _find_occluder(collider)
		if occluder != null and not found.has(occluder):
			found.append(occluder)
	_set_active(found)


func _exit_tree() -> void:
	_set_active([])


func _set_active(next: Array[CameraOccluder3D]) -> void:
	var requester_id: int = get_instance_id()
	for occluder: CameraOccluder3D in _active:
		if is_instance_valid(occluder) and not next.has(occluder):
			occluder.clear_fade(requester_id)
	for occluder: CameraOccluder3D in next:
		if not _active.has(occluder):
			occluder.request_fade(requester_id)
	if _same_members(_active, next):
		return
	_active = next
	occluders_changed.emit(_active)


func _find_occluder(node: Node) -> CameraOccluder3D:
	var current: Node = node
	while current != null:
		if current is CameraOccluder3D:
			return current as CameraOccluder3D
		for child: Node in current.get_children():
			if child is CameraOccluder3D:
				return child as CameraOccluder3D
		current = current.get_parent()
	return null


func _same_members(left: Array[CameraOccluder3D], right: Array[CameraOccluder3D]) -> bool:
	if left.size() != right.size():
		return false
	for item: CameraOccluder3D in left:
		if not right.has(item):
			return false
	return true
