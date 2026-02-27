extends CanvasLayer

var run_seed: int = 0
var rng_rooms := RandomNumberGenerator.new()
var step_index: int = 0

func start_new_run(seed_value: int) -> void:
	run_seed = seed_value
	step_index = 0
	rng_rooms.seed = run_seed
	print(run_seed)
	
	
func seed_from_string(s: String) -> int:
	return hash(s.strip_edges())
	

var target_spawn_name: String = ""
@export var room_scenes: Array[PackedScene] = []

@export var end_scene: PackedScene
var _last_scene: PackedScene = null
var recent_rooms: Array[PackedScene] = []

@export var room_base_weights: Array[float] = [] # same length as room_scenes

var room_weights: Array[float] = [] # runtime copy that you modify
var increased_weight: float = 5.0

@export var recent_limit := 3

var _busy := false

@onready var fade: ColorRect = ColorRect.new()

@export var setup_room: PackedScene
@export var door_room: PackedScene

@export var dash_scene: PackedScene
@export var double_jump_scene: PackedScene
@export var inverse_gravity_scene: PackedScene
@export var phase_scene: PackedScene

func _ready() -> void:
		
	Inventory.key_added.connect(_on_key_added)
	Inventory.key_removed.connect(_on_key_removed)
	Inventory.keys_cleared.connect(_on_keys_cleared)
	Progress.door_unlocked.connect(_on_door_unlocked)

			
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.anchor_left = 0
	fade.anchor_top = 0
	fade.anchor_right = 1
	fade.anchor_bottom = 1
	add_child(fade)
		
	if room_base_weights.size() != room_scenes.size():
		room_base_weights.resize(room_scenes.size())
		for i in range(room_base_weights.size()):
			if room_scenes[i] == setup_room:
				room_base_weights[i] = 2.0
			else:
				room_base_weights[i] = 1.0
			
	room_weights = room_base_weights.duplicate()

func _on_key_added(key_id: String) -> void:
	set_weight_by_scene(door_room, increased_weight)
	debug_weights()

func _on_key_removed(key_id: String) -> void:
	if Inventory.keys.is_empty():
		set_weight_by_scene(door_room, 1.0)
		debug_weights()

func _on_keys_cleared() -> void:
	set_weight_by_scene(door_room, 1.0)
	debug_weights()

func _on_door_unlocked(door_id: String) -> void:
	var scene = match_id_to_scene(door_id)

	if scene != null:
		set_weight_by_scene(scene, 0.0)

	set_weight_by_scene(setup_room, increased_weight)
	debug_weights() 
		
func debug_weights():
	print("---- WEIGHTS ----")
	for i in range(room_scenes.size()):
		print(room_scenes[i], ":", room_weights[i])
		
func _on_ability_switched(a: int) -> void:
	# reset all ability rooms (but don't re-enable disabled ones)
	_set_weight_if_not_disabled(dash_scene, 1.0)
	_set_weight_if_not_disabled(double_jump_scene, 1.0)
	_set_weight_if_not_disabled(inverse_gravity_scene, 1.0)
	_set_weight_if_not_disabled(phase_scene, 1.0)

	# boost selected one (also don't re-enable disabled)
	match a:
		Player.Ability.DASH:
			_set_weight_if_not_disabled(dash_scene, increased_weight)
		Player.Ability.DOUBLE_JUMP:
			_set_weight_if_not_disabled(double_jump_scene, increased_weight)
		Player.Ability.INVERT_GRAVITY:
			_set_weight_if_not_disabled(inverse_gravity_scene, increased_weight)
		Player.Ability.PHASE:
			_set_weight_if_not_disabled(phase_scene, increased_weight)
		_:
			push_warning("Unknown ability enum value: %s" % str(a))

	debug_weights()
	
func _set_weight_if_not_disabled(scene: PackedScene, w: float) -> void:
	var idx := room_scenes.find(scene)
	if idx == -1:
		push_warning("Scene not found in room_scenes")
		return

	# If disabled, keep it disabled
	if room_weights[idx] <= 0.0:
		return

	room_weights[idx] = w
						
func match_id_to_scene(id: String) -> PackedScene:
	var _scene: PackedScene = null

	match id:
		"DASH_DOOR":
			_scene = dash_scene

		"DOUBLE_JUMP_DOOR":
			_scene = double_jump_scene

		"INVERSE_GRAVITY_DOOR":
			_scene = inverse_gravity_scene

		"PHASE_DOOR":
			_scene = phase_scene

		_:
			push_warning("match_id_to_scene(): unknown id '%s'" % id)

	return _scene
	
func set_weight_by_scene(scene: PackedScene, w: float) -> void:
	var index := room_scenes.find(scene)
	if index == -1:
		push_warning("Scene not found in room_scenes")
		return

	room_weights[index] = w


func _pick_weighted_room() -> PackedScene:
	if room_scenes.is_empty():
		return null

	# Build candidate indices
	var candidates: Array[int] = []
	for i in range(room_scenes.size()):
		var s := room_scenes[i]
		if s == null:
			continue
		if s == _last_scene:
			continue
		if recent_rooms.has(s):
			continue
		if room_weights[i] <= 0.0:
			continue
		candidates.append(i)

	# fallback: allow recent rooms but still avoid immediate repeat if possible
	if candidates.is_empty():
		for i in range(room_scenes.size()):
			var s := room_scenes[i]
			if s == null:
				continue
			if s == _last_scene:
				continue
			if room_weights[i] <= 0.0:
				continue
			candidates.append(i)

	# last fallback: anything with weight > 0
	if candidates.is_empty():
		for i in range(room_scenes.size()):
			if room_scenes[i] != null and room_weights[i] > 0.0:
				candidates.append(i)

	if candidates.is_empty():
		return null

	# Weighted roll
	var total := 0.0
	for i in candidates:
		total += room_weights[i]

	# Seeded roll (step-based)
	var step_rng := RandomNumberGenerator.new()
	step_rng.seed = hash(str(run_seed) + ":" + str(step_index))
	step_index += 1

	var r := step_rng.randf() * total
	for i in candidates:
		r -= room_weights[i]
		if r <= 0.0:
			var choice := room_scenes[i]
			_track_recent(choice)
			_last_scene = choice
			return choice

	# safety fallback
	var choice := room_scenes[candidates.back()]
	_track_recent(choice)
	_last_scene = choice
	return choice

func _track_recent(choice: PackedScene) -> void:
	if recent_rooms.size() >= recent_limit:
		recent_rooms.pop_front()
	recent_rooms.append(choice)


func go_random(spawn_name: String) -> bool:
	if _busy:
		return false

	_busy = true

	var next_scene := _pick_weighted_room()
	if next_scene == null:
		_busy = false
		return false

	call_deferred("_go_random_impl", next_scene, spawn_name)
	return true

func _go_random_impl(next_scene: PackedScene, spawn_name: String) -> void:
	await _fade_to(1.0, 0.18)

	var world := get_tree().current_scene
	if world and world.has_method("_load_room_packed"):
		world.call("_load_room_packed", next_scene, spawn_name)
	else:
		push_warning("World missing _load_room_packed")
		_busy = false
		return

	await get_tree().process_frame
	await _fade_to(0.0, 0.18)
	_busy = false
	
	
func _fade_to(alpha: float, time: float) -> void:
	var t := create_tween()
	t.tween_property(fade, "color:a", alpha, time)
	await t.finished
	
func respawn_to_checkpoint(room_scene: PackedScene, spawn_pos: Vector2) -> void:
	if _busy:
		return
	_busy = true

	# fade out
	await _fade_to(1.0, 0.18)

	var world := get_tree().current_scene
	if world:
			## different room: reload the checkpoint room
			if world.has_method("_load_room_checkpoint"):
				world.call("_load_room_checkpoint", room_scene, spawn_pos)
			else:
				push_warning("World missing _load_room_checkpoint(room_scene, pos)")

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
	
