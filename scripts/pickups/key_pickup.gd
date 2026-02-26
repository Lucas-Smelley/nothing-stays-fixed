extends Area2D

@export var key_id: String = "KEY"
@export var follow_offset := Vector2(0, -22)

@onready var sprite_2d: Sprite2D = $Sprite2D

var _collected := false
var _pending_player: Node2D

@export var float_distance := 2.0
@export var float_speed := 1.0

var _start_y := 0.0

var _bob_tween: Tween


func _ready() -> void:
	collision_mask = 0
	set_collision_mask_value(2, true)
	body_entered.connect(_on_body_entered)

	_start_y = sprite_2d.position.y
	_bob(sprite_2d, _start_y, float_distance, float_speed)


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if not body.is_in_group("player"):
		return

	_collected = true
	_pending_player = body as Node2D

	Inventory.add_key(key_id)
	call_deferred("_finish_collect")


func _finish_collect() -> void:
	if not is_instance_valid(_pending_player):
		queue_free()
		return

	monitoring = false
	monitorable = false
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true

	reparent(_pending_player)
	position = follow_offset

	add_to_group("carried_key")

	# Stop the old float tween (important so it doesn't keep running)
	if _bob_tween and _bob_tween.is_running():
		_bob_tween.kill()

	# Bob the carried key (the Area2D) around follow_offset.y
	_bob(self, follow_offset.y, 4.0, 0.6)


func _bob(target: Node, base_y: float, distance: float, speed: float) -> void:
	_bob_tween = create_tween()
	_bob_tween.set_loops()
	_bob_tween.tween_property(target, "position:y", base_y - distance, speed)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(target, "position:y", base_y + distance, speed)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
