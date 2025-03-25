# encounter_stage.gd
extends StaticBody3D

signal challenge_scene_ready
signal challenge_scene_cleaned_up

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# Stage configuration
var stage_bounds: Vector2 = Vector2(10.0, 10.0)  # Default size
var is_active: bool = false

func _ready() -> void:
	# Initialization setup
	pass

func setup_stage(challenge_type: EncounterManager.ChallengeType, config: Dictionary) -> void:
	# Resize stage based on challenge type
	var stage_size := _get_stage_size(challenge_type)
	if not _resize_stage(stage_size):
		push_error("Failed to resize challenge stage")
		return
	
	# Setup boundary detection
	_setup_boundary_area(stage_size)
	
	# Mark stage as active
	is_active = true
	
	emit_signal("challenge_scene_ready")

func activate() -> void:
	is_active = true

func deactivate() -> void:
	is_active = false
	cleanup()

func _get_stage_size(type: EncounterManager.ChallengeType) -> Vector2:
	match type:
		EncounterManager.ChallengeType.COLLECTION: 
			return Vector2(20.0, 20.0)
		EncounterManager.ChallengeType.PLATFORMING: 
			return Vector2(30.0, 30.0)
		EncounterManager.ChallengeType.TIMED_TASK: 
			return Vector2(15.0, 15.0)
		EncounterManager.ChallengeType.PUZZLE: 
			return Vector2(25.0, 25.0)
		_: 
			return Vector2(10.0, 10.0)

func _resize_stage(size: Vector2) -> bool:
	stage_bounds = size
	
	# Ensure the required nodes exist
	if not is_instance_valid(mesh_instance) or not is_instance_valid(collision_shape):
		push_error("Missing mesh or collision shape for stage resizing")
		return false
	
	# Resize mesh
	var mesh = mesh_instance.mesh
	if mesh is PlaneMesh:
		mesh.size = size
	elif mesh is BoxMesh:
		mesh.size = Vector3(size.x, mesh.size.y, size.y)
	
	# Resize collision shape
	var collision = collision_shape.shape
	if collision is BoxShape3D:
		collision.size = Vector3(size.x, collision.size.y, size.y)
	
	return true

func _setup_boundary_area(size: Vector2) -> void:
	# Previous boundary area setup method remains the same
	# This ensures players stay within the challenge stage
	var area = Area3D.new()
	area.name = "BoundaryArea"
	
	var margin = 2.0
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(size.x + margin, 10.0, size.y + margin)
	
	var collision = CollisionShape3D.new()
	collision.shape = box_shape
	area.add_child(collision)
	
	area.body_exited.connect(_on_body_exit_boundary)
	
	add_child(area)

func _on_body_exit_boundary(body: Node3D) -> void:
	# Existing boundary exit handling method remains the same
	# This provides a bounce-back mechanism for players
	if body.is_in_group("player"):
		# Bounce player back logic
		var player_pos = body.global_position
		var center = global_position
		
		var half_x = stage_bounds.x / 2 - 1.0
		var half_z = stage_bounds.y / 2 - 1.0
		var new_x = clamp(player_pos.x, center.x - half_x, center.x + half_x)
		var new_z = clamp(player_pos.z, center.z - half_z, center.z + half_z)
		
		body.global_position = Vector3(new_x, player_pos.y, new_z)
		
		# Add bounce effect
		_play_bounce_effect(body.global_position)

func _play_bounce_effect(position: Vector3) -> void:
	HUDManager.show_message({
		"text": "Boing!",
		"color": Color.YELLOW,
		"duration": 0.5
	})

func cleanup() -> void:
	# Remove any spawned objects or reset stage
	is_active = false
	emit_signal("challenge_scene_cleaned_up")
