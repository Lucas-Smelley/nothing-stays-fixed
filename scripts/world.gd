extends Node2D
class_name World

@onready var room_container: Node2D = $RoomContainer
@onready var player: Node = $Player

var current_room: Node = null

func _ready() -> void:
	# load an initial room
	_load_room("res://scenes/rooms/setup_room.tscn", "Spawn_Left")

func _load_room(room_path: String, spawn_name: String) -> void:
	# remove old room
	
	if current_room:
		current_room.queue_free()
		current_room = null

	# add new room
	var packed := load(room_path) as PackedScene
	current_room = packed.instantiate()
	room_container.add_child(current_room)
	var tilemap := current_room.get_node_or_null("TileMap_Room")
	RoomContext.set_room(current_room, tilemap)

	# move player to spawn
	var spawn := current_room.get_node_or_null(spawn_name)
	if spawn:
		player.global_position = (spawn as Node2D).global_position

	else:
		push_warning("Missing spawn: %s in %s" % [spawn_name, room_path])
		
	if player.has_method("init_default_checkpoint"):
		player.call("init_default_checkpoint")


func _load_room_checkpoint(room_path: String, spawn_pos: Vector2) -> void:
	if current_room:
		current_room.queue_free()
		current_room = null

	var packed: PackedScene = load(room_path)
	current_room = packed.instantiate()
	room_container.add_child(current_room)

	# update RoomContext (adjust tilemap node path/name if needed)
	var tilemap := current_room.get_node_or_null("TileMap_Room")
	RoomContext.set_room(current_room, tilemap)

	player.global_position = spawn_pos
	player.velocity = Vector2.ZERO



	
