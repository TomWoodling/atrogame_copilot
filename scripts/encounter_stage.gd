extends StaticBody3D

const DEFAULT_NPC = preload("res://scenes/default_npc.tscn")
const DEFAULT_COLLECTABLE = preload("res://scenes/default_collectable.tscn")

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var interaction_zone: Area3D = $InteractionZone

var encounter_config: Dictionary
var current_object: Node3D
var pending_setup: Dictionary

func _ready() -> void:
	# If we had a pending setup from before nodes were ready, apply it now
	if not pending_setup.is_empty():
		_apply_setup(pending_setup)

# Called by world_generator with configuration
func setup_encounter(config: Dictionary) -> void:
	# Store the configuration
	encounter_config = config
	
	# Check if we're ready to apply the setup
	if not is_node_ready():
		pending_setup = config
		return
	
	_apply_setup(config)

func _apply_setup(config: Dictionary) -> void:
	# Verify our required nodes exist before proceeding
	if not mesh_instance or not collision_shape:
		push_warning("Required nodes not initialized during setup")
		pending_setup = config  # Store for retry after ready
		return
		
	# Adjust stage size based on type
	var stage_size := _get_stage_size(config.type)
	_resize_stage(stage_size)
	
	# Ensure proper height above terrain
	var height_diff: float = config.surrounding_height - config.terrain_height
	if height_diff > 0:
		position.y += height_diff
	
	# Configure interaction zone if it exists
	if interaction_zone and interaction_zone.has_method("configure"):
		interaction_zone.configure(config)
	
	# Spawn type-specific objects
	_spawn_encounter_object(config.type)

func _get_stage_size(type: String) -> Vector2:
	match type:
		"npc": return Vector2(4.0, 4.0)
		"collection": return Vector2(3.0, 3.0)
		"info": return Vector2(2.5, 2.5)
		"special_challenge": return Vector2(8.0, 8.0)  # Larger stage for special challenges
		_: return Vector2(1.0, 1.0)

func _resize_stage(size: Vector2) -> void:
	# Safety check for mesh_instance
	if not is_instance_valid(mesh_instance):
		push_warning("mesh_instance not valid during resize attempt")
		return
		
	var mesh := mesh_instance.mesh as BoxMesh
	if mesh:
		mesh.size = Vector3(size.x, 0.1, size.y)
	else:
		push_warning("mesh not found or not BoxMesh type")
		return
		
	# Safety check for collision_shape
	if is_instance_valid(collision_shape):
		var shape := collision_shape.shape as BoxShape3D
		if shape:
			shape.size = Vector3(size.x, 0.1, size.y)
			
func _spawn_encounter_object(type: String) -> void:
	if current_object:
		current_object.queue_free()
	
	match type:
		"npc":
			current_object = DEFAULT_NPC.instantiate()
		"collection":
			current_object = DEFAULT_COLLECTABLE.instantiate()
		"info":
			return  # Info encounters don't need physical objects
	
	if current_object:
		add_child(current_object)
		current_object.position.y = 0.1  # Slight offset above stage

func cleanup() -> void:
	if current_object and is_instance_valid(current_object):
		current_object.queue_free()
	current_object = null
