extends Area2D

@onready var label: Label = $AnimatedSprite2D/Label
var label_is_visible = false

func _ready() -> void:
	label.visible = false
	
func set_label_visibility() -> void:
	if label_is_visible:
		label.visible = false
		label_is_visible = false
	else:
		label.visible = true
		label_is_visible = true
		
func interact(player: Player) -> void:
	player.switch_ability(Player.Ability.PHASE)
	
	queue_free()
