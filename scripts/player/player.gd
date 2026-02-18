extends CharacterBody2D

class_name Player

@export var move_speed: float = 160.0

@export var gravity: float = 1000.0
@export var max_fall_speed: float = 500
@export var jump_speed: float = 300.0

@export var wall_slide_speed: float = 80.0
@export var wall_jump_x: float = 120.0
@export var wall_jump_y: float = 300.0
@export var wall_jump_lock_time: float = 0.12
@export var wall_stick_time: float = 0.12

@export var coyote_time: float = 0.14
@export var jump_buffer_time: float = 0.10

enum Ability { NONE, DOUBLE_JUMP, DASH, PHASE, INVERT_GRAVITY }
var equipped_ability: Ability = Ability.NONE
var ability_charges: int = 0

@export var dash_speed := 350.0
@export var dash_time := 0.22

@export var phase_time := 3.0
@export var phase_wall_layer := 3

@export var checkpoint_scene: PackedScene 

var checkpoint_instance: Node2D = null 

var _grav_sign: int = 1 # 1 = normal, -1 inverted


var _is_phasing := false
var _phase_timer := 0.0
var _saved_mask := 0

var _coyote_timer := 0.0
var _jump_buffer := 0.0
var _wall_jump_lock := 0.0
var _wall_stick_timer := 0.0
var _dash_timer := 0.0

var _was_on_wall := false
var _air_jumped := false
var _is_dashing := false

var _facing_dir: int = 1

var checkpoint_position: Vector2 

@onready var interaction_area: Area2D = $InteractionArea
var _interact_offset_x: float = 12
var nearby_interactables: Array[Node2D] = []

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var _anim_locked := false
var _locked_anim := ""
var _lock_interruptible := false

signal ability_changed(ability_name: String, charges: int)

func _ready() -> void:
	sprite.animation_finished.connect(_on_anim_finished)
	
	_emit_ability_ui()
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	_interact_offset_x = interaction_area.position.x
	checkpoint_position = global_position
	

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")
	
	if input_dir != 0:
		_facing_dir = sign(input_dir)
		interaction_area.position.x = _interact_offset_x * _facing_dir
		sprite.flip_h = _facing_dir < 0

	var grounded := is_on_floor() if _grav_sign == 1 else is_on_ceiling()

	# timers
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_wall_jump_lock = maxf(_wall_jump_lock - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time
	
	if Input.is_action_just_pressed("use_ability"):
		_handle_ability_pressed()
		
	if Input.is_action_just_pressed("interact"):
		var target = _get_best_interactable()
		if target:
			target.interact(self)

	if _is_dashing:
		_dash_timer -= delta
		velocity.x = _facing_dir * dash_speed

		if _dash_timer <= 0:
			_is_dashing = false
			
	if _is_phasing:
		_phase_timer -= delta
		
		if _phase_timer <= 0:
			_end_phase()
	
	# refresh coyote
	if grounded:
		_coyote_timer = coyote_time
		_air_jumped = false
	

	# gravity
	if not grounded and not _is_dashing:
		velocity.y += gravity * _grav_sign * delta
		
		if _grav_sign > 0:
			velocity.y = min(velocity.y, max_fall_speed)
		else:
			velocity.y = max(velocity.y, -max_fall_speed)


	# wall info
	var on_wall := is_on_wall() and not grounded
	if on_wall and not _was_on_wall:
		_wall_stick_timer = wall_stick_time
		_air_jumped = false
	var wall_normal := get_wall_normal() if on_wall else Vector2.ZERO
	
	if not on_wall:
		_wall_stick_timer = 0.0

	# instant horizontal 
	if _wall_jump_lock <= 0.0 and not _is_dashing:
		velocity.x = input_dir * move_speed
		
	var falling := velocity.y * _grav_sign > 0.0  # moving with gravity

	# wall slide (press into wall)
	if on_wall and falling:
		if input_dir != 0 and signf(input_dir) == -signf(wall_normal.x):

			if _wall_stick_timer > 0.0:
				_wall_stick_timer -= delta
				velocity.y = 0.0
			else:
				velocity.y = _grav_sign * minf(absf(velocity.y), wall_slide_speed)

	# buffered jump
	if _jump_buffer > 0.0:
		if _coyote_timer > 0.0:
			velocity.y += -jump_speed * _grav_sign
			_jump_buffer = 0.0
			_coyote_timer = 0.0
		elif on_wall:
			velocity.y = -jump_speed * _grav_sign
			velocity.x = wall_normal.x * wall_jump_x
			_jump_buffer = 0.0
			_wall_jump_lock = wall_jump_lock_time
		elif equipped_ability == Ability.DOUBLE_JUMP and ability_charges > 0 and not _air_jumped:
			velocity.y = 0.0
			velocity.y += -jump_speed * _grav_sign
			_air_jumped = true
			_consume_charge()
			
			lock_anim("double_jump")
	
	#Set checkpoint 
	if Input.is_action_just_pressed("set_checkpoint"):
		set_checkpoint()
		
	_was_on_wall = on_wall

	move_and_slide()
	
	
	if _is_dashing:
		_play_anim("dash")
	elif on_wall and falling and input_dir != 0 and signf(input_dir) == -signf(get_wall_normal().x):
		_play_anim("wall_slide")
	elif not grounded:
		# optional: separate jump/fall if you want
		_play_anim("jump")
	elif absf(velocity.x) > 0.1:
		_play_anim("run")
	else:
		_play_anim("idle")



func _play_anim(name: String) -> void:
	# If locked, only allow the locked animation to be played
	if _anim_locked and name != _locked_anim:
		return

	if sprite.animation != name:
		sprite.play(name)

func _on_anim_finished() -> void:
	# Only unlock if the thing that finished is the locked one
	if _anim_locked and sprite.animation == _locked_anim:
		_anim_locked = false
		_locked_anim = ""


func lock_anim(name: String, interruptible := false) -> void:
	_anim_locked = true
	_locked_anim = name
	_lock_interruptible = interruptible

	# Make sure it starts from frame 0
	sprite.play(name)



func _on_interaction_area_entered(body: Node) -> void:
	if body.is_in_group("interactable"):
		nearby_interactables.append(body)

func _on_interaction_area_exited(body: Node) -> void:
	if body.is_in_group("interactable"):
		nearby_interactables.erase(body)


func _get_best_interactable() -> Node2D:
	
	var closest_interactble: Node2D = null
	var closest_distance = INF
	
	for interactble in nearby_interactables:
		var dist := global_position.distance_to(interactble.global_position)
		
		if dist < closest_distance:
			closest_distance = dist
			closest_interactble = interactble

	return closest_interactble
	
func switch_ability(a: Ability) -> void:
	equipped_ability = a
	_emit_ability_ui()
	
	
func _emit_ability_ui() -> void:
	ability_changed.emit(Ability.keys()[equipped_ability], ability_charges)

func add_charges(amount: int) -> void:
	ability_charges += amount
	_emit_ability_ui()

func _consume_charge() -> bool:
	if ability_charges <= 0:
		return false
	ability_charges -= 1
	_emit_ability_ui()
	return true

func _handle_ability_pressed() -> void:
	match equipped_ability:
		Ability.DASH:
			if _consume_charge():
				_start_dash()
		Ability.PHASE:
			if _consume_charge():
				_start_phase()
		Ability.INVERT_GRAVITY:
			if _consume_charge():
				_toggle_gravity()
		Ability.DOUBLE_JUMP:
			pass # jump key handles it
		_:
			pass

func _start_dash() -> void:
	_is_dashing = true
	_dash_timer = dash_time
	velocity.y = 0.0

func _start_phase() -> void:
	_is_phasing = true
	_phase_timer = phase_time

	_saved_mask = collision_mask
	collision_mask &= ~(1 << (phase_wall_layer - 1)) # remove that bit
	
func _end_phase() -> void:
	_is_phasing = false
	collision_mask = _saved_mask

	
func _toggle_gravity() -> void:
	_grav_sign *= -1
	
	lock_anim("rotate")

	# optional: snap small vertical velocity to avoid weird float
	velocity.y = 0.0

	# flip visuals (don’t flip the CharacterBody2D root)
	sprite.flip_v = (_grav_sign < 0)
	# or if you're using a mesh:
	# mesh.scale.y = abs(mesh.scale.y) * (_grav_sign)
	
func set_checkpoint():
	print("checkpoint set")
	checkpoint_position = global_position
	
	if checkpoint_instance:
		checkpoint_instance.queue_free() 
		
	if checkpoint_scene:
		checkpoint_instance = checkpoint_scene.instantiate()
		get_parent().add_child(checkpoint_instance)
		checkpoint_instance.global_position = checkpoint_position

func respawn():
	global_position = checkpoint_position 
	velocity = Vector2.ZERO
	print("respawna")
	
