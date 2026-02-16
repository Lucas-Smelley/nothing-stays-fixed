extends Area2D

func interact(player: Player) -> void:
	player.switch_ability(Player.Ability.DASH)
	
	queue_free()
