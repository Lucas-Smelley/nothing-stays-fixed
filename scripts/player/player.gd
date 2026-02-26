extends CharacterBody2D

class_name Player

@onready var hurtbox: Area2D = $Hurtbox
const HAZARD_LAYER := 6
var ceiling_layer := 9
var up_dir := Vector2.UP

@export var move_speed: float = 140.0

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
signal ability_switched(ability: Ability)

@export var dash_speed := 350.0
@export var dash_time := 0.22

@export var phase_time := 3.0
@export var laser_layer := 3
var _is_phasing := false
var _phase_timer := 0.0

var checkpoint_room_scene: PackedScene
var checkpoint_position: Vector2 = Vector2.ZERO
var has_checkpoint := false

var _grav_sign: int = 1 # 1 = normal, -1 inverted


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
var _interact_offset_x: float = 12
var nearby_interactables: Array[Node2D] = []


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var _anim_locked := false
var _locked_anim := ""
var _lock_interruptible := false
var _is_respawning := false
var _is_dead := false

@onready var wall_check: RayCast2D = $WallCheck

signal ability_changed(ability_name: String, charges: int)

@onready var sfx: AudioStreamPlayer2D = $SFX
@export var jump: AudioStream
@export var dash: AudioStream
@export var death: AudioStream
@export var gravity_sound: AudioStream

@onready var run: AudioStreamPlayer2D = $run
@export var phase: AudioStreamPlayer2D

func play_sfx(stream: AudioStream) -> void:
	if stream == null: return
	sfx.stop()
	sfx.stream = stream
	sfx.play()

func _ready() -> void:
	
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	
	sprite.animation_finished.connect(_on_anim_finished)
	
	_emit_ability_ui()
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	_interact_offset_x = interaction_area.position.x
	


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")
	
	if input_dir != 0:
		_facing_dir = sign(input_dir)
		interaction_area.position.x = _interact_offset_x * _facing_dir
		sprite.flip_h = _facing_dir < 0
		
	if _facing_dir > 0:
		wall_check.target_position = Vector2(10,0)
	else:
		wall_check.target_position = Vector2(-10,0)

	var grounded := is_on_floor() if _grav_sign == 1 else is_on_ceiling()
	
	if grounded and input_dir != 0:
		if not run.playing:
			run.play()
	else:
		if run.playing:
			run.stop()
			
	var moving_against_up := velocity.dot(up_dir) > 0.0
	set_collision_mask_value(ceiling_layer, moving_against_up)
		
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
		if not phase.playing:
			phase.play()
		
		if _phase_timer <= 0:
			if phase.playing:
				phase.stop()
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
	var raw_on_wall := is_on_wall() and not grounded
	var wall_normal := get_wall_normal() if raw_on_wall else Vector2.ZERO
	var on_climb_wall := raw_on_wall and wall_is_climbable()
	
	if on_climb_wall and not _was_on_wall:
		_wall_stick_timer = wall_stick_time
		_air_jumped = false
	
	if not on_climb_wall:
		_wall_stick_timer = 0.0

	# instant horizontal 
	if _wall_jump_lock <= 0.0 and not _is_dashing:
		velocity.x = input_dir * move_speed
		
	var falling := velocity.y * _grav_sign > 0.0  # moving with gravity

	# wall slide (press into wall)
	if on_climb_wall and falling:
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
		elif on_climb_wall:
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
		play_sfx(jump)
		
	_was_on_wall = on_climb_wall

	move_and_slide()
	
	if _is_dead or _is_respawning:
		return
		
	if not _is_phasing and player_touching_laser():
		_is_respawning = true
		await _death_and_respawn()
		_is_respawning = false
		return
		
	if _is_dashing:
		_play_anim("dash")
	elif on_climb_wall and falling and input_dir != 0 and signf(input_dir) == -signf(get_wall_normal().x):
		_play_anim("wall_slide")
	elif not grounded:
		_play_anim("jump")
	elif absf(velocity.x) > 0.1:
		_play_anim("run")
	else:
		_play_anim("idle")


func init_default_checkpoint() -> void:
	checkpoint_position = global_position
	checkpoint_room_scene = RoomContext.current_room_scene
	has_checkpoint = true


func _on_hurtbox_body_entered(body: Node) -> void:
	if _is_respawning:
		return
			
	_is_respawning = true
	await _death_and_respawn()
	_is_respawning = false
	
func wall_is_climbable() -> bool:
	if not wall_check.is_colliding():
		return false

	var tilemap: TileMapLayer = RoomContext.current_tilemap
	if tilemap == null:
		return false

	var collider = wall_check.get_collider()

	var point: Vector2 = wall_check.get_collision_point()
	var normal: Vector2 = wall_check.get_collision_normal()

	# Nudge point slightly INTO the wall tile to avoid border rounding
	point -= normal * 0.5

	var local_point = tilemap.to_local(point)
	var cell: Vector2i = tilemap.local_to_map(local_point)

	var td: TileData = tilemap.get_cell_tile_data(cell)

	if td == null:
		return false

	# List the value we get back
	var val = td.get_custom_data("climbable")

	return val == true

func _update_animation():
	if _is_dead or _is_respawning:
		return
	# ... your normal idle/run/jump anim selection ...


func _play_anim(anim_name: String) -> void:
	# If locked, only allow the locked animation to be played
	if _anim_locked and anim_name != _locked_anim:
		return

	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _on_anim_finished() -> void:
	# Only unlock if the thing that finished is the locked one
	if _anim_locked and sprite.animation == _locked_anim:
		_anim_locked = false
		_locked_anim = ""


func lock_anim(anim_name: String, interruptible := false) -> void:
	_anim_locked = true
	_locked_anim = anim_name
	_lock_interruptible = interruptible

	sprite.play(anim_name)

func play_locked_anim_and_wait(anim_name: String) -> void:
	lock_anim(anim_name)

	await sprite.animation_finished

	# Safety: if you ever allow interruptions, you can enforce:
	# while sprite.animation == anim_name:
	#     await sprite.animation_finished


func _on_interaction_area_entered(body: Node) -> void:
	if body.is_in_group("interactable"):
		if body.has_method("set_label_visibility"):
			body.set_label_visibility()
		nearby_interactables.append(body)

func _on_interaction_area_exited(body: Node) -> void:
	if body.is_in_group("interactable"):
		if body.has_method("set_label_visibility"):
			body.set_label_visibility()
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
	ability_switched.emit(a)
	
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
				play_sfx(gravity_sound)
		Ability.DOUBLE_JUMP:
			pass # jump key handles it
		_:
			pass

func _start_dash() -> void:
	_is_dashing = true
	_dash_timer = dash_time
	velocity.y = 0.0
	play_sfx(dash)

func _start_phase() -> void:
	set_phase_enabled(true)
	
	_is_phasing = true
	_phase_timer = phase_time

	
func _end_phase() -> void:
	set_phase_enabled(false)
	
	_is_phasing = false
	
func player_touching_laser() -> bool:
	var tilemap: TileMapLayer = RoomContext.current_tilemap
	if tilemap == null:
		return false

	var p := tilemap.local_to_map(tilemap.to_local(global_position))
	var td := tilemap.get_cell_tile_data(p)

	return td != null and td.get_custom_data("laser") == true

func set_phase_enabled(enabled: bool):
	var mat := sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("phase_active", enabled)


func _toggle_gravity() -> void:
	_grav_sign *= -1

	lock_anim("rotate")

	sprite.flip_v = (_grav_sign < 0)
	
	
func set_checkpoint():
	checkpoint_room_scene = RoomContext.current_room_scene
	checkpoint_position = global_position
	has_checkpoint = true
	

func _clear_carried_keys_on_death() -> void:
	# 1) clear inventory data
	Inventory.clear_keys()

	# 2) free any key nodes currently attached to the player
	for c in get_children():
		if c.is_in_group("carried_key"):
			c.queue_free()


func _death_and_respawn() -> void:
	if not has_checkpoint:
		return
	_is_dead = true
	play_sfx(death)

	# stop movement
	velocity = Vector2.ZERO
	set_physics_process(false)
	# 1) death animation
	await play_locked_anim_and_wait("die")
	
	# fade out, scene move/load, fade in
	await Transition.respawn_to_checkpoint(checkpoint_room_scene, checkpoint_position)
	reset_on_death()
	# respawn animation
	await play_locked_anim_and_wait("respawn")
	set_physics_process(true)
	_is_dead = false
	
func reset_on_death() -> void:
	if _grav_sign == -1:
		_toggle_gravity()
	if _is_phasing:
		_end_phase()
	
	if _is_dashing:
		_is_dashing = false
		_dash_timer = 0.0
		
	_clear_carried_keys_on_death()


	
