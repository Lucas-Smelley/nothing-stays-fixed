extends CharacterBody2D

class_name Player

@export var move_speed: float = 220.0

@export var gravity: float = 1400.0
@export var jump_speed: float = 420.0

@export var wall_slide_speed: float = 110.0
@export var wall_jump_x: float = 260.0
@export var wall_jump_y: float = 420.0
@export var wall_jump_lock_time: float = 0.14 
@export var wall_stick_time: float = 0.15

@export var coyote_time: float = 0.14
@export var jump_buffer_time: float = 0.10

enum Ability { NONE, DOUBLE_JUMP, DASH, PHASE, INVERT_GRAVITY }
var equipped_ability: Ability = Ability.NONE
var ability_charges: int = 0

@export var dash_speed := 450.0
@export var dash_time := 0.22

@export var phase_time := 3.0
@export var phase_wall_layer := 3

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

@onready var interaction_area: Area2D = $InteractionArea
var nearby_interactables: Array[Node2D] = []

signal ability_changed(ability_name: String, charges: int)

func _ready() -> void:
	
	_emit_ability_ui()
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")
	
	if input_dir != 0:
		_facing_dir = sign(input_dir)

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
	if is_on_floor():
		_coyote_timer = coyote_time
		_air_jumped = false
	

	# gravity
	if not is_on_floor() and not _is_dashing:
		velocity.y += gravity * delta

	# wall info
	var on_wall := is_on_wall() and not is_on_floor()
	if on_wall and not _was_on_wall:
		_wall_stick_timer = wall_stick_time
	var wall_normal := get_wall_normal() if on_wall else Vector2.ZERO
	
	if not on_wall:
		_wall_stick_timer = 0.0


	# instant horizontal 
	if _wall_jump_lock <= 0.0 and not _is_dashing:
		velocity.x = input_dir * move_speed

	# wall slide (press into wall)
	if on_wall and velocity.y > 0.0:
		if input_dir != 0 and signf(input_dir) == -signf(wall_normal.x):

			if _wall_stick_timer > 0.0:
				_wall_stick_timer -= delta
				velocity.y = 0.0
			else:
				velocity.y = minf(velocity.y, wall_slide_speed)


	# buffered jump
	if _jump_buffer > 0.0:
		if _coyote_timer > 0.0:
			velocity.y = -jump_speed
			_jump_buffer = 0.0
			_coyote_timer = 0.0
		elif on_wall:
			velocity.y = -wall_jump_y
			velocity.x = wall_normal.x * wall_jump_x
			_jump_buffer = 0.0
			_wall_jump_lock = wall_jump_lock_time
		elif equipped_ability == Ability.DOUBLE_JUMP and ability_charges > 0 and not _air_jumped:
			velocity.y = -jump_speed
			_air_jumped = true
			_consume_charge()

	
	_was_on_wall = on_wall

	move_and_slide()


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
	print("gravity toggled")
