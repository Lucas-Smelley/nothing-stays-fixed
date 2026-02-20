extends Area2D

@export var key_id: String = "KEY"
@export var follow_offset := Vector2(0, -22)

var _collected := false
var _pending_player: Node2D

func _ready() -> void:
	collision_mask = 0
	set_collision_mask_value(2, true)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if not body.is_in_group("player"):
		return

	_collected = true
	_pending_player = body as Node2D

	Inventory.add_key(key_id)

	# IMPORTANT: defer any removal/reparent/shape disabling
	call_deferred("_finish_collect")

func _finish_collect() -> void:
	if not is_instance_valid(_pending_player):
		queue_free()
		return

	# Disable collisions safely (now we're not in the physics callback)
	monitoring = false
	monitorable = false
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true

	# Reparent to player so it follows them
	reparent(_pending_player)
	position = follow_offset

	_start_bob()

func _start_bob() -> void:
	var t := create_tween()
	t.set_loops()
	t.tween_property(self, "position:y", follow_offset.y - 4, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "position:y", follow_offset.y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
