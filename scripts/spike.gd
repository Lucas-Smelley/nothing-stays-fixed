extends Area2D

@export var player_node: NodePath
var player: Node = null 

func _ready():
	body_entered.connect(_on_body_entered)
	
	if player != null:
		player = get_node(player_node)
	
func _on_body_entered(body):
	if body == player:
		player.respawn()
