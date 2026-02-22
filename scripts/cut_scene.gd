extends Control

@export var cutscene_textures: Array[Texture2D] = []
@export var world_scene: PackedScene

@onready var image: TextureRect = $TextureRect
@onready var fade: ColorRect = $Fade

@onready var loading: Label = $labels/loading
@onready var classic_fight: Label = $labels/ClassicFight
@onready var welcome: ColorRect = $labels/welcome
@onready var settings: ColorRect = $labels/settings
@onready var fall: ColorRect = $labels/fall
@onready var breakdown: ColorRect = $labels/breakdown
@onready var alone: Label = $labels/alone
@onready var unscripted: Label = $labels/unscripted


var current_scene := 0
var _busy := false

func _ready() -> void:
	if cutscene_textures.is_empty():
		push_warning("No cutscene textures assigned.")
		_go_to_world()
		return

	_show_frame(current_scene)
	fade.color.a = 0.0
	
	

func _process(_delta: float) -> void:
	if _busy:
		return

	if Input.is_action_just_pressed("jump"):
		_busy = true
		await _advance()
		_busy = false

func _advance() -> void:
	# fade out to black
	await _fade_to(1.0, 0.18)

	# move to next or finish
	if current_scene + 1 >= cutscene_textures.size():
		_go_to_world()
		return
	

	current_scene += 1
	_show_frame(current_scene)

	# fade back in
	await _fade_to(0.0, 0.18)

func _show_frame(index: int) -> void:
	image.texture = cutscene_textures[index]

	# default: hide all
	loading.visible = false
	classic_fight.visible = false
	welcome.visible = false
	settings.visible = false
	fall.visible = false
	breakdown.visible = false
	alone.visible = false
	unscripted.visible = false

	# show the one you want
	match index:
		0:
			loading.visible = true
		1:
			classic_fight.visible = true
		2:
			welcome.visible = true
		3:
			settings.visible = true
		4:
			fall.visible = true
		5:
			breakdown.visible = true
		6:
			alone.visible = true
		7:
			unscripted.visible = true

func _go_to_world() -> void:
	if world_scene:
		get_tree().change_scene_to_packed(world_scene)
	else:
		get_tree().change_scene_to_file("res://World.tscn")

func _fade_to(alpha: float, time: float) -> void:
	var t := create_tween()
	t.tween_property(fade, "color:a", alpha, time)
	await t.finished
	
