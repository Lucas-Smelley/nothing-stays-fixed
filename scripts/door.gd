extends Area2D

@export var exit_side: String = "right"

var _used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node) -> void:
	print("Door triggered: ", exit_side)

	if _used: 
		return
	if not body.is_in_group("player"):
		return
	_used = true
	
	var spawn_name = ""
	
	if exit_side == "right":
		spawn_name = "Spawn_Left"
	else:
		spawn_name = "Spawn_Right"
		
	Transition.go_random(spawn_name)
