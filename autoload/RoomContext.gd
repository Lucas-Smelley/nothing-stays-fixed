extends Node

var current_room_scene: PackedScene
var current_room_instance: Node
var current_tilemap: TileMapLayer = null

func set_room(scene: PackedScene, instance: Node, tilemap: TileMapLayer) -> void:
	current_room_scene = scene
	current_room_instance = instance
	current_tilemap = tilemap
