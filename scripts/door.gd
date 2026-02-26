extends Area2D

@export var exit_side: String = "right"

var _used := false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node) -> void:
	if _used:
		print("Im used naw")
		return
	if not body.is_in_group("player"):
		print("U aint player")
		return

	var spawn_name := "Spawn_Left" if exit_side == "right" else "Spawn_Right"

	if not Transition.go_random(spawn_name):
		return

	_used = true
	print("continue from door:", get_path())
