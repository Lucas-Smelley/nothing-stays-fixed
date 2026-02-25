extends Node

var current_room: Node = null
var current_tilemap: TileMapLayer = null
var current_room_path: String = ""

func set_room(room: Node, tilemap: TileMapLayer, room_path: String) -> void:

	current_room = room
	current_tilemap = tilemap
	current_room_path = room_path


	if room_path == "":
		push_error("RoomContext received EMPTY room_path!")
