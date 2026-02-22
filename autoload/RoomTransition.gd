extends CanvasLayer

class_name RoomTransition

@export var rooms_folder := "res://scenes/rooms"
var room_pool: Array[String] = []
var target_spawn_name: String = ""


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
	
	_build_room_pool()

func _build_room_pool() -> void:
	room_pool.clear()

	var dir := DirAccess.open(rooms_folder)
	if dir == null:
		push_error("Could not open rooms folder: " + rooms_folder)
		return

	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".tscn"):
			room_pool.append(rooms_folder + "/" + file)
		file = dir.get_next()
	dir.list_dir_end()

	if room_pool.is_empty():
		push_warning("No rooms found in: " + rooms_folder)
		
func go_random(spawn_name: String) -> void:
	if _busy: 
		return
	target_spawn_name = spawn_name
	
	_busy = true
	
	var next_room = _pick_random_room()
	
	await _fade_to(1.0, 0.18)
	
	var world := get_tree().current_scene
	if world and world.has_method("_load_room"):
		world.call("_load_room", next_room, target_spawn_name)
	
	await get_tree().process_frame
	await _fade_to(0.0, 0.18)
	
	_busy = false
	
func _pick_random_room() -> String:
	if room_pool.size() == 1:
		return room_pool[0]
		
	var candidates = room_pool.duplicate()
	candidates.erase(_last_room)
	
	var choice = candidates[randi() % candidates.size()]
	
	_last_room = choice
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
	
	await _fade_to(1.0, 0.18)
	
	get_tree().change_scene_to_file("res://scenes/end_scene.tscn")	
	await _fade_to(0.0, 0.18)
	
