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
	# Safety check for required config
	if not config.has("type"):
		push_error("Encounter stage setup missing required 'type' parameter")
		return
		
	# Ensure our nodes are properly initialized
	 # Check if nodes are ready
	if not is_instance_valid(mesh_instance) or not is_instance_valid(collision_shape):
		# Defer the setup until nodes are ready
		call_deferred("_apply_setup", config)
		return
	
	# Adjust stage size based on type
	var stage_size := _get_stage_size(config.type)
	if not _resize_stage(stage_size):
		push_error("Failed to resize stage")
		return
	
	# this is not needed as determined by world_generator.gd
	#if config.has("surrounding_height") and config.has("terrain_height"):
	#	var height_diff: float = config.surrounding_height - config.terrain_height
	#	if height_diff > 0:
	#		position.y += height_diff
	
	# Configure interaction zone if it exists
	if is_instance_valid(interaction_zone) and interaction_zone.has_method("configure"):
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

func _resize_stage(size: Vector2) -> bool:
	print("resizing")
	# Safety check for mesh_instance
	if not is_instance_valid(mesh_instance):
		push_warning("mesh_instance not valid during resize attempt")
		return false
	
	# Check if mesh exists and is the correct type
	var mesh := mesh_instance.mesh
	if not mesh:
		push_warning("No mesh found on mesh_instance")
		return false
	
	if not mesh is BoxMesh:
		push_warning("Mesh is not a BoxMesh, found: " + mesh.get_class())
		return false
	
	# Create a unique copy of the mesh before modifying it
	var box_mesh := mesh.duplicate() as BoxMesh
	mesh_instance.mesh = box_mesh  # Assign the unique copy back
	box_mesh.size = Vector3(size.x, 0.1, size.y)
	
	# Resize the collision shape - also make it unique
	if is_instance_valid(collision_shape):
		var shape := collision_shape.shape
		if shape is BoxShape3D:
			var unique_shape := shape.duplicate() as BoxShape3D
			collision_shape.shape = unique_shape  # Assign the unique copy back
			unique_shape.size = Vector3(size.x, 0.1, size.y)
		else:
			push_warning("Collision shape is not a BoxShape3D")
			return false
	else:
		push_warning("collision_shape not valid during resize attempt")
		return false
	
	return true
			
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
