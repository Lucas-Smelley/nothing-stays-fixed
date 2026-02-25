extends CanvasLayer

class_name RoomTransition

var target_spawn_name: String = ""

@export var room_scenes: Array[PackedScene] = []
@export var end_scene: PackedScene
var _last_scene: PackedScene = null

var recent_rooms: Array[PackedScene] = []


var _busy := false
var _last_room: String = ""

@onready var fade: ColorRect = ColorRect.new()

func _ready() -> void:
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.anchor_left = 0
	fade.anchor_top = 0
	fade.anchor_right = 1
	fade.anchor_bottom = 1
	add_child(fade)
	

func go_random(spawn_name: String) -> void:
	if _busy:
		return
	_busy = true

	target_spawn_name = spawn_name

	var next_scene: PackedScene = _pick_random_room()
	if next_scene == null:
		push_error("No rooms assigned in RoomTransition!")
		_busy = false
		return

	await _fade_to(1.0, 0.18)

	var world := get_tree().current_scene
	if world and world.has_method("_load_room_packed"):
		world.call("_load_room_packed", next_scene, target_spawn_name)

	await get_tree().process_frame
	await _fade_to(0.0, 0.18)

	_busy = false
	
func _pick_random_room() -> PackedScene:
	if room_scenes.is_empty():
		return null

	if room_scenes.size() == 1:
		_last_scene = room_scenes[0]
		return room_scenes[0]

	var candidates: Array[PackedScene] = room_scenes.duplicate()
	candidates.erase(_last_scene)

	for room in recent_rooms:
		candidates.erase(room)

	if candidates.is_empty():
		candidates = room_scenes.duplicate()
		candidates.erase(_last_scene) # optional but recommended

	var choice: PackedScene = candidates[randi() % candidates.size()]

	# keep last 3 rooms
	if recent_rooms.size() >= 3:
		recent_rooms.pop_front()
	recent_rooms.append(choice)

	_last_scene = choice
	return choice
	
func _fade_to(alpha: float, time: float) -> void:
	var t := create_tween()
	t.tween_property(fade, "color:a", alpha, time)
	await t.finished
	
func respawn_to_checkpoint(room_path: String, spawn_pos: Vector2) -> void:
	if _busy:
		return
	_busy = true

	# fade out
	await _fade_to(1.0, 0.18)

	var world := get_tree().current_scene
	if world:
			## different room: reload the checkpoint room
			if world.has_method("_load_room_checkpoint"):
				world.call("_load_room_checkpoint", room_path, spawn_pos)
			else:
				push_warning("World missing _load_room_checkpoint(room_path, pos)")

	# give one frame for transforms/scene changes to Ftle
	await get_tree().process_frame

	# fade in
	await _fade_to(0.0, 0.18)

	_busy = false

func go_to_end() -> void:
	if end_scene == null:
		push_error("end_scene is not assigned in RoomTransition!")
		return

	await _fade_to(1.0, 0.18)

	get_tree().change_scene_to_packed(end_scene)

	await get_tree().process_frame
	await _fade_to(0.0, 0.18)
	
