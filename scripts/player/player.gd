extends CharacterBody2D

@export var move_speed: float = 220.0

@export var gravity: float = 1400.0
@export var jump_speed: float = 420.0

@export var wall_slide_speed: float = 110.0
@export var wall_jump_x: float = 260.0
@export var wall_jump_y: float = 420.0
@export var wall_jump_lock_time: float = 0.12 
@export var wall_stick_time: float = 0.15

@export var coyote_time: float = 0.08
@export var jump_buffer_time: float = 0.10

var _coyote_timer := 0.0
var _jump_buffer := 0.0
var _wall_jump_lock := 0.0
var _wall_stick_timer := 0.0

var _was_on_wall := false


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")

	# timers
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_wall_jump_lock = maxf(_wall_jump_lock - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time

	# refresh coyote
	if is_on_floor():
		_coyote_timer = coyote_time

	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# wall info
	var on_wall := is_on_wall() and not is_on_floor()
	if on_wall and not _was_on_wall:
		_wall_stick_timer = wall_stick_time
	var wall_normal := get_wall_normal() if on_wall else Vector2.ZERO


	# instant horizontal 
	if _wall_jump_lock <= 0.0:
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
	
	_was_on_wall = on_wall

	move_and_slide()
