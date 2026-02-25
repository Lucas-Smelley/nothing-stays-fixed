extends Node2D
class_name World

@onready var room_container: Node2D = $RoomContainer
@onready var player: Node = $Player

var current_room: Node = null

func _ready() -> void:
	# load an initial room
	_load_room("res://scenes/rooms/setup_room.tscn", "Spawn_Left")

func _load_room(room_path: String, spawn_name: String) -> void:
	if current_room:
		current_room.queue_free()
		current_room = null

	var packed := load(room_path)
	if packed == null or not (packed is PackedScene):
		push_error("FAILED TO LOAD ROOM: " + room_path)
		return

	current_room = (packed as PackedScene).instantiate()
	room_container.add_child(current_room)

	var tilemap := current_room.get_node_or_null("TileMap_Room")

	var spawn := current_room.get_node_or_null(spawn_name)
	if spawn and spawn is Node2D:
		player.global_position = (spawn as Node2D).global_position
	else:
		push_warning("Missing spawn (or not Node2D): %s in %s" % [spawn_name, room_path])

	RoomContext.set_room(current_room, tilemap, room_path)

	if player.has_method("set_checkpoint"):
		player.call("set_checkpoint")


func _load_room_checkpoint(room_path: String, spawn_pos: Vector2) -> void:
	if current_room:
		current_room.queue_free()
		current_room = null

	var packed := load(room_path)
	if packed == null or not (packed is PackedScene):
		push_error("FAILED TO LOAD CHECKPOINT ROOM: " + room_path)
		return

	current_room = (packed as PackedScene).instantiate()
	room_container.add_child(current_room)

	var tilemap := current_room.get_node_or_null("TileMap_Room")
	RoomContext.set_room(current_room, tilemap, room_path)

	player.global_position = spawn_pos

	if "velocity" in player:
		player.velocity = Vector2.ZERO

func _load_room_packed(packed: PackedScene, spawn_name: String) -> void:
	if packed == null:
		push_error("_load_room_packed called with packed == null")
		return

	if current_room:
		current_room.queue_free()
		current_room = null

	current_room = packed.instantiate()
	room_container.add_child(current_room)

	var tilemap := current_room.get_node_or_null("TileMap_Room")
	RoomContext.set_room(current_room, tilemap, packed.resource_path)

	var spawn := current_room.get_node_or_null(spawn_name)
	if spawn and spawn is Node2D:
		player.global_position = (spawn as Node2D).global_position
	else:
		push_warning("Missing spawn (or not Node2D): %s in %s" % [spawn_name, packed.resource_path])

	if player.has_method("set_checkpoint"):
		player.call("set_checkpoint")
	
