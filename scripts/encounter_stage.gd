extends StaticBody3D

const DEFAULT_NPC = preload("res://scenes/default_npc.tscn")
const DEFAULT_COLLECTABLE = preload("res://scenes/default_collectable.tscn")

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var interaction_zone: Area3D = $InteractionZone

var current_object: Node3D = null
var is_active: bool = false

# This will be called by the level/world to position and configure the stage
func setup_encounter(type: String, height_offset: float = 1.0) -> void:
	# Position the stage at the right height
	position.y += height_offset
	
	match type:
		"npc":
			_spawn_npc()
		"collection":
			_spawn_collectable()
		"info":
			# Info encounters don't need a physical object
			pass

func _spawn_npc() -> void:
	if current_object:
		current_object.queue_free()
	
	current_object = DEFAULT_NPC.instantiate()
	add_child(current_object)
	# Position slightly above the stage
	current_object.position.y = 0.1

func _spawn_collectable() -> void:
	if current_object:
		current_object.queue_free()
		
	current_object = DEFAULT_COLLECTABLE.instantiate()
	add_child(current_object)
	# Position slightly above the stage
	current_object.position.y = 0.1

func cleanup() -> void:
	if current_object:
		current_object.queue_free()
		current_object = null
