extends Control

@export var cutscene_textures: Array[Texture2D] = []

@onready var image: TextureRect = $TextureRect
@onready var fade: ColorRect = $Fade

@onready var quit_button: Button = $Quit
@onready var play_again: Button = $PlayAgain

@export var intro_scene: PackedScene


var current_scene := 0

func _ready() -> void:

	_show_frame(current_scene)
	fade.color.a = 0.0
	play_again.pressed.connect(_on_play_again_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_play_again_pressed() -> void:
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
	
