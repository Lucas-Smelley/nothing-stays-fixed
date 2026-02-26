extends Node
signal door_unlocked(door_id: String)

var unlocked_doors: Dictionary = {}

func is_door_unlocked(door_id: String) -> bool:
	return unlocked_doors.get(door_id, false)

func unlock_door(door_id: String) -> void:
	if door_id == "":
		push_warning("Tried to unlock empty door_id")
		return
	if unlocked_doors.get(door_id, false):
		return

	unlocked_doors[door_id] = true
	door_unlocked.emit(door_id)

	if unlocked_doors.size() == 4:
		game_clear()

func reset_run() -> void:
	unlocked_doors.clear()

func game_clear() -> void:
	Transition.go_to_end()
