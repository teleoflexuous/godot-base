class_name CameraOcclusionTracker2D
extends Node2D

signal occluders_changed(occluders: Array[CameraOccluder2D])

@export var focus_path: NodePath
@export var camera_path: NodePath
@export_flags_2d_physics var collision_mask: int = 1
@export_range(1, 32, 1) var maximum_hits: int = 8
@export var excluded_collision_paths: Array[NodePath] = []

var _active: Array[CameraOccluder2D] = []


func _physics_process(_delta: float) -> void:
	var focus: Node2D = get_node_or_null(focus_path) as Node2D
	var camera: Node2D = get_node_or_null(camera_path) as Node2D
	if focus == null or camera == null or not is_inside_tree():
		_set_active([])
		return
	var exclude: Array[RID] = []
	for path: NodePath in excluded_collision_paths:
		var object: CollisionObject2D = get_node_or_null(path) as CollisionObject2D
		if object != null:
			exclude.append(object.get_rid())
	var found: Array[CameraOccluder2D] = []
	for _query_index: int in range(maximum_hits):
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			focus.global_position,
			camera.global_position,
			collision_mask,
			exclude
		)
		var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			break
		var collider: CollisionObject2D = hit.get(&"collider") as CollisionObject2D
		if collider == null:
			break
		exclude.append(collider.get_rid())
		var occluder: CameraOccluder2D = _find_occluder(collider)
		if occluder != null and not found.has(occluder):
			found.append(occluder)
	_set_active(found)


func _exit_tree() -> void:
	_set_active([])


func _set_active(next: Array[CameraOccluder2D]) -> void:
	var requester_id: int = get_instance_id()
	for occluder: CameraOccluder2D in _active:
		if is_instance_valid(occluder) and not next.has(occluder):
			occluder.clear_fade(requester_id)
	for occluder: CameraOccluder2D in next:
		if not _active.has(occluder):
			occluder.request_fade(requester_id)
	if _same_members(_active, next):
		return
	_active = next
	occluders_changed.emit(_active)


func _find_occluder(node: Node) -> CameraOccluder2D:
	var current: Node = node
	while current != null:
		if current is CameraOccluder2D:
			return current as CameraOccluder2D
		for child: Node in current.get_children():
			if child is CameraOccluder2D:
				return child as CameraOccluder2D
		current = current.get_parent()
	return null


func _same_members(left: Array[CameraOccluder2D], right: Array[CameraOccluder2D]) -> bool:
	if left.size() != right.size():
		return false
	for item: CameraOccluder2D in left:
		if not right.has(item):
			return false
	return true
