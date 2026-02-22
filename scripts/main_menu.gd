extends Control

@export var intro_scene: PackedScene

@onready var start_button: Button = $Start
@onready var quit_button: Button = $Quit

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	if intro_scene:
		get_tree().change_scene_to_packed(intro_scene)
	else:
		return

func _on_quit_pressed() -> void:
	get_tree().quit()
