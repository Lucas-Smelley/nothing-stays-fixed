extends Area2D

@export var amount: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.add_charges(1)
		queue_free()
