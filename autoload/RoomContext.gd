extends Node

var current_room: Node = null
var current_tilemap: TileMapLayer = null

func set_room(room: Node, tilemap: TileMapLayer) -> void:
	current_room = room
	current_tilemap = tilemap
