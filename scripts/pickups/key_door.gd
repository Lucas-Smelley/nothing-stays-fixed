extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var required_key_id: String = "KEY"
@export var door_id: String = ""

var _player_inside := false
var _opened := false

func _ready() -> void:
	collision_mask = 0
	set_collision_mask_value(2, true)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	animated_sprite.play("idle")


func set_door_id(id: String) -> void:
	door_id = id

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	_try_open()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false



func _is_unlocked_now() -> bool:
	# already permanently unlocked?
	if door_id != "" and Progress.is_door_unlocked(door_id):
		return true
	# otherwise must have the key
	return Inventory.has_key(required_key_id)


func _try_open() -> void:
	if _opened:
		return
	if not _player_inside:
		return
	if not _is_unlocked_now():
		return

	_opened = true

	# 1) Persist door unlock
	if door_id != "":
		Progress.unlock_door(door_id)
	else:
		push_warning("Door opened but door_id is empty; progress will not persist.")

	# 2) Consume key from Inventory
	if required_key_id != "" and Inventory.has_key(required_key_id):
		Inventory.remove_key(required_key_id)

	# 3) Destroy the carried key node attached to the player (visual)
	_destroy_carried_key_node(required_key_id)
	
	animated_sprite.play("clear")
	await animated_sprite.animation_finished

	call_deferred("queue_free")


func _destroy_carried_key_node(key_id: String) -> void:
	if key_id == "":
		return

	# Keys are reparented to the player and put in group "carried_key"
	for n in get_tree().get_nodes_in_group("carried_key"):
		# Key script has @export var key_id, so we can check it
		if "key_id" in n and n.key_id == key_id:
			n.call_deferred("queue_free")
			return
