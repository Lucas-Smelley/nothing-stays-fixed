extends Node2D
class_name Room

@onready var tile_map_room: TileMapLayer = $TileMap_Room

func _ready() -> void:
	
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
		
	var spawn_name = Transition.target_spawn_name
	if spawn_name == "":
		return
		
	var spawn = get_node_or_null(spawn_name)
	if spawn == null:
		push_warning("Missing spawn marker: " + spawn_name)
		return
	
	player.global_position = spawn.global_position
	
	Transition.target_spawn_name = ""
