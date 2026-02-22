extends Control

@export var cutscene_textures: Array[Texture2D] = []

@onready var image: TextureRect = $TextureRect
@onready var fade: ColorRect = $Fade

@onready var quit_button: Button = $Quit
@onready var start_button: Button = $Start

@export var intro_scene: PackedScene


var current_scene := 0

func _ready() -> void:

	_show_frame(current_scene)
	fade.color.a = 0.0
	start_button.pressed.connect(_on_start_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_start_pressed() -> void:
	if intro_scene:
		get_tree().change_scene_to_packed(intro_scene)
	else:
		return
		
func _show_frame(index: int) -> void:
	image.texture = cutscene_textures[index]


func _fade_to(alpha: float, time: float) -> void:
	var t := create_tween()
	t.tween_property(fade, "color:a", alpha, time)
	await t.finished
	
