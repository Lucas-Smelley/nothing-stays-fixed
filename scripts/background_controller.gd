extends Node

@export var static_sprite_path: NodePath
@export var mid_sprite_path: NodePath
@export var fore_sprite_path: NodePath

@export_range(0.0, 1.0) var static_strength := 0.35
@export_range(0.0, 1.0) var mid_strength := 0.55
@export_range(0.0, 1.0) var fore_strength := 0.25

func _ready() -> void:
	randomize()

	var s: Sprite2D = get_node(static_sprite_path)
	var m: Sprite2D = get_node(mid_sprite_path)
	var f: Sprite2D = get_node(fore_sprite_path)

	# Make sure materials are unique so changes don't affect all sprites
	s.material = s.material.duplicate()
	m.material = m.material.duplicate()
	f.material = f.material.duplicate()

	_apply_random_tint(s, static_strength)
	_apply_random_tint(m, mid_strength)
	_apply_random_tint(f, fore_strength)

func _apply_random_tint(sprite: Sprite2D, strength: float) -> void:
	var tint := _random_pleasant_color()
	sprite.material.set_shader_parameter("tint", tint)
	sprite.material.set_shader_parameter("strength", strength)

func _random_pleasant_color() -> Color:
	# Random hue, but keep saturation/value in a nice range so it doesn't look gross
	var h := randf()                  # 0..1
	var sat := randf_range(0.45, 0.85)
	var val := randf_range(0.70, 1.00)
	return Color.from_hsv(h, sat, val, 1.0)
