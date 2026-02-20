extends Node

signal key_added(key_id: String)

var keys := {} 

func has_key(key_id: String) -> bool:
	return keys.has(key_id)

func add_key(key_id: String) -> void:
	if keys.has(key_id):
		return
	keys[key_id] = true
	key_added.emit(key_id)
