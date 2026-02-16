extends CanvasLayer

@onready var ability_label: Label = $AbilityLabel
@onready var charges_label: Label = $ChargesLabel

@onready var player := %Player


func _ready() -> void:
	if player:
		player.ability_changed.connect(_on_ability_changed)


func _on_ability_changed(ability_name: String, charges: int) -> void:
	ability_label.text = "Ability: %s" % ability_name
	charges_label.text = "Charges: %d" % charges
