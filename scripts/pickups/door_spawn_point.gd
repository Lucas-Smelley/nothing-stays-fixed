extends Marker2D
class_name DoorSpawnPoint

@export var door_id: String = ""
@export var door_scene: PackedScene  # drag one of your 4 door scenes here
@export var spawn_when_unlocked: bool = false
# keep false if you want unlocked doors to disappear
