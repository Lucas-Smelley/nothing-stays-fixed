extends Control

@export var intro_scene: PackedScene

@onready var start_button: Button = $Start
@onready var quit_button: Button = $Quit

@onready var seed_input: LineEdit = $SeedInput

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	var raw := seed_input.text.strip_edges()
	var seed_value: int

	if raw == "":
		seed_value = Time.get_unix_time_from_system() 
	elif raw.is_valid_int():
		seed_value = int(raw)
	else:
		seed_value = Transition.seed_from_string(raw)

	Transition.start_new_run(seed_value)
	get_tree().change_scene_to_packed(intro_scene)
	
	
func _on_quit_pressed() -> void:
	get_tree().quit()
