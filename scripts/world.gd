extends Node2D
class_name World

@onready var room_container: Node2D = $RoomContainer
@onready var player: Node = $Player

var current_room: Node = null

@export var initial_room: PackedScene

func _ready() -> void:
	if player.has_signal("ability_switched"):
		if not player.ability_switched.is_connected(Transition._on_ability_switched):
			player.ability_switched.connect(Transition._on_ability_switched)
			
	_load_room_packed(initial_room, "Spawn_Left")


func _load_room_checkpoint(packed: PackedScene, spawn_pos: Vector2) -> void:
	if packed == null:
		push_error("Checkpoint packed scene is null")
		return

	if current_room:
		current_room.queue_free()
		current_room = null

	current_room = packed.instantiate()
	room_container.add_child(current_room)

	var tilemap := current_room.get_node_or_null("TileMap_Room")
	RoomContext.set_room(packed, current_room, tilemap)

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
	RoomContext.set_room(packed, current_room, tilemap)

	var spawn := current_room.get_node_or_null(spawn_name)
	if spawn and spawn is Node2D:
		player.global_position = (spawn as Node2D).global_position
	else:
		push_warning("Missing spawn (or not Node2D): %s" % spawn_name)

	if player.has_method("set_checkpoint"):
		player.call("set_checkpoint")
	
