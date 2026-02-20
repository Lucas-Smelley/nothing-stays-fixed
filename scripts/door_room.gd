extends Room # <-- change path to your actual base room script

func _ready() -> void:
	super._ready()
	_spawn_locked_doors()

func _spawn_locked_doors() -> void:
	var spawn_points := _get_door_spawn_points(self)

	for sp: DoorSpawnPoint in spawn_points:

		if sp.door_scene == null:
			push_warning("DoorSpawnPoint missing door_scene for door_id: " + sp.door_id)
			continue

		var unlocked: bool = Progress.is_door_unlocked(sp.door_id)

		# You asked: only spawn doors that haven't been cleared
		if unlocked and not sp.spawn_when_unlocked:
			continue

		var door := sp.door_scene.instantiate()
		add_child(door)
		door.global_position = sp.global_position

		# give the door its id so it can unlock itself later
		if door.has_method("set_door_id"):
			door.call("set_door_id", sp.door_id)
		elif "door_id" in door:
			door.door_id = sp.door_id

func _get_door_spawn_points(root: Node) -> Array[DoorSpawnPoint]:
	var result: Array[DoorSpawnPoint] = []
	for child in root.get_children():
		if child is DoorSpawnPoint:
			result.append(child)
		result.append_array(_get_door_spawn_points(child))
	return result
