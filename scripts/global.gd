extends Node3D


func get_time() -> float:
	return Time.get_ticks_msec() / 1000.0


func wait(time: float) -> Signal:
	return get_tree().create_timer(time).timeout


func do_raycast(
	origin: Vector3, dir: Vector3, length: float = 100.0, mask: int = 1 << 0
) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var end = origin + dir * length
	var query = PhysicsRayQueryParameters3D.create(origin, end, mask)
	return space_state.intersect_ray(query)
