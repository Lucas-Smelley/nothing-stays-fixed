extends Area2D

func interact(player: Player) -> void:
	player.switch_ability(Player.Ability.PHASE)
	
	queue_free()
