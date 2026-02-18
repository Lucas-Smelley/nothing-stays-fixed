extends AnimatedSprite2D

@export var float_distance := 2.0
@export var float_speed := 1.0

var _start_y := 0.0

func _ready():
	_start_y = position.y
	_start_float()

func _start_float():
	var tween = create_tween()
	tween.set_loops() # infinite loop
	
	tween.tween_property(self, "position:y", _start_y - float_distance, float_speed)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(self, "position:y", _start_y + float_distance, float_speed)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
