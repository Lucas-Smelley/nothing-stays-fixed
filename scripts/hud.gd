extends CanvasLayer

@onready var ability_label: Label = $AbilityLabel
@onready var charges_label: Label = $ChargesLabel

@onready var player := %Player

@onready var seed_label: Label = $SeedLabel

func _ready() -> void:
	if player:
		player.ability_changed.connect(_on_ability_changed)
		
	Transition.set_seed.connect(_on_set_seed)

	if Transition.run_seed != 0:
		_on_set_seed(Transition.run_seed)


func _on_ability_changed(ability_name: String, charges: int) -> void:
	ability_label.text = "Ability: %s" % ability_name
	charges_label.text = "Charges: %d" % charges

func _on_set_seed(seed_int: int) -> void:
	print("recieved")
	$SeedLabel.text = "Seed: " + str(seed_int)
	
