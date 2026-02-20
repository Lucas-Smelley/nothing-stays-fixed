extends Area2D

@export var required_key_id: String = "KEY"
@export var is_final_door := false

var _player_inside := false
var _unlocked := false

func _ready() -> void:
	collision_mask = 0
	set_collision_mask_value(2, true)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	Inventory.key_added.connect(_on_key_added)

	_refresh_lock_state()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_try_open()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _on_key_added(_key_id: String) -> void:
	_refresh_lock_state()
	if _player_inside:
		_try_open()

func _refresh_lock_state() -> void:
	_unlocked = Inventory.has_key(required_key_id)
	# TODO: update visuals (locked/unlocked animation)

func _try_open() -> void:
	if not _unlocked:
		# TODO: show “needs bug fixer X” prompt / locked shake
		return

	# Door opens
	# TODO: play open anim, disable collision, transition, etc.
	if is_final_door:
		# TODO: trigger win
		pass
