# Inventory.gd
extends Node

signal key_added(key_id: String)
signal key_removed(key_id: String)
signal keys_cleared()

var keys := {}

func has_key(key_id: String) -> bool:
	return keys.has(key_id)

func add_key(key_id: String) -> void:
	if keys.has(key_id):
		return
	keys[key_id] = true
	key_added.emit(key_id)

func remove_key(key_id: String) -> void:
	if not keys.has(key_id):
		return
	keys.erase(key_id)
	key_removed.emit(key_id)

func clear_keys() -> void:
	if keys.is_empty():
		return
	keys.clear()
	keys_cleared.emit()
