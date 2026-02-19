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

	# move player to spawn
	var spawn := current_room.get_node_or_null(spawn_name)
	if spawn:
		player.global_position = (spawn as Node2D).global_position
	else:
		push_warning("Missing spawn: %s in %s" % [spawn_name, room_path])

func load_room_checkpoint(checkpoint: Node2D, checkpoint_scene: PackedScene) -> void:
	if current_room:
		current_room.queue_free()
		current_room = null
	
	var packed := checkpoint_scene
	current_room = packed.instantiate()
	room_container.add_child(current_room)
	
	
	if checkpoint:
		player.global_position = checkpoint.global_position
	else:
		push_warning("Missing spawn: %s in %s" % [checkpoint_scene])
	
