extends Node3D

signal stage_created(stage: Node3D, encounter_type: StringName)

# Terrain Generation Constants
const CHUNK_SIZE: int = 100
const TERRAIN_HEIGHT_RANGE: Vector2 = Vector2(-2.0, 2.5)
const NOISE_PARAMS = {
	"frequency": 0.005,
	"terrain_scale": 10.0,
	"detail_scale": 2.0
}

const STAGES_PER_CHUNK = {
	"min": 1,
	"max": 3,
	"min_spacing": 20.0,
	"height_offset": 0.0  # Explicit height offset for better accessibility
}
# Encounter type weights and configurations
# Modify the ENCOUNTER_TYPES constant to reflect our current needs
const ENCOUNTER_TYPES = {
	"info": { 
		"weight": 0.4,  # More common as they're tutorial/story elements
		"min_spacing": 30.0  # Spread info encounters further apart
	},
	"npc": { 
		"weight": 0.3,
		"min_spacing": 20.0
	},
	"collection": { 
		"weight": 0.3,
		"min_spacing": 15.0  # Can be closer together
	}
}

const SCANNABLE_SPAWN_CONFIG = {
	"per_chunk": {
		"min": 2,
		"max": 4
	},
	"min_spacing": 15.0,  # Minimum distance between scannable objects
	"height_offset": 0.5   # How far above terrain to spawn
}

# Internal state
var noise: FastNoiseLite
var detail_noise: FastNoiseLite
var generated_chunks: Dictionary = {}
var current_chunk: Vector2i
var player: Node3D

@onready var encounter_stage: PackedScene = preload("res://scenes/stages/encounter_stage.tscn")
@onready var scannable_object: PackedScene = preload("res://scenes/objects/default_scannable_object.tscn")

func _ready() -> void:
	if not encounter_stage:
		push_error("WorldGenerator: Failed to load encounter_stage scene. Check the resource path.")
		return
	setup_noise()
	await get_tree().process_frame
	initialize_world()

func _physics_process(_delta: float) -> void:
	if not player:
		return
		
	var player_chunk := get_chunk_coords(player.global_position)
	if current_chunk != player_chunk:
		check_chunks(player.global_position)

func setup_noise() -> void:
	# Main terrain noise
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN  # Fixed: Updated enum name
	noise.seed = randi()
	noise.frequency = NOISE_PARAMS.frequency
	
	# Detail noise for added variation
	detail_noise = FastNoiseLite.new()
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN  # Fixed: Updated enum name
	detail_noise.seed = randi() + 1  # Different seed for variation
	detail_noise.frequency = NOISE_PARAMS.frequency * 2.0  # Higher frequency for details

func initialize_world() -> void:
	player = get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		push_error("WorldGenerator: Player node not found or is not Node3D. Make sure player is in the 'player' group.")
		return
	
	current_chunk = get_chunk_coords(Vector3.ZERO)
	check_chunks(Vector3.ZERO)

func get_chunk_coords(pos: Vector3) -> Vector2i:
	return Vector2i(
		floori(pos.x / CHUNK_SIZE),
		floori(pos.z / CHUNK_SIZE)
	)

func generate_chunk(chunk_coords: Vector2i) -> void:
	if generated_chunks.has(chunk_coords):
		return
		
	var chunk := Node3D.new()
	chunk.name = "Chunk_%d_%d" % [chunk_coords.x, chunk_coords.y]
	add_child(chunk)
	
	chunk.position = Vector3(
		chunk_coords.x * CHUNK_SIZE,
		0,
		chunk_coords.y * CHUNK_SIZE
	)
	
	var terrain := generate_terrain_mesh(chunk_coords)
	if terrain:
		chunk.add_child(terrain)
		generate_stages(chunk, chunk_coords)
		spawn_scannable_objects(chunk, chunk_coords)  # Add this line
		generated_chunks[chunk_coords] = chunk
	else:
		chunk.queue_free()
		push_error("WorldGenerator: Failed to generate terrain for chunk %s" % chunk_coords)

func generate_terrain_mesh(chunk_coords: Vector2i) -> MeshInstance3D:
	# Create a plane mesh for the base
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	plane_mesh.subdivide_width = 32
	plane_mesh.subdivide_depth = 32
	
	# Create an ArrayMesh to modify
	var array_mesh := ArrayMesh.new()
	var surface_arrays := plane_mesh.surface_get_arrays(0)
	
	# Get vertices and modify their heights
	var vertices: PackedVector3Array = surface_arrays[Mesh.ARRAY_VERTEX]
	var modified_vertices := PackedVector3Array()
	modified_vertices.resize(vertices.size())
	
	# Modify the height of each vertex
	for i in range(vertices.size()):
		var vertex := vertices[i]
		var world_pos := vertex + Vector3(chunk_coords.x * CHUNK_SIZE, 0, chunk_coords.y * CHUNK_SIZE)
		
		var height := get_height_at_point(world_pos)
		modified_vertices[i] = Vector3(vertex.x, height, vertex.z)
	
	# Replace the vertices in the surface arrays
	surface_arrays[Mesh.ARRAY_VERTEX] = modified_vertices
	
	# Add the modified surface to the array mesh
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
	
	# Create the mesh instance
	var terrain := MeshInstance3D.new()
	terrain.mesh = array_mesh
	
	# Create a simple material
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.7, 0.2)  # Green for grass
	terrain.material_override = material
	
	# Add collision
	var static_body := StaticBody3D.new()
	var collision_shape := CollisionShape3D.new()
	
	# Create a concave collision shape from the mesh
	var shape := array_mesh.create_trimesh_shape()
	collision_shape.shape = shape
	
	static_body.add_child(collision_shape)
	terrain.add_child(static_body)
	
	return terrain

func get_height_at_point(world_pos: Vector3) -> float:
	var base_height := noise.get_noise_2d(world_pos.x, world_pos.z)
	var detail := detail_noise.get_noise_2d(world_pos.x * 2.0, world_pos.z * 2.0)
	
	# Remap from [-1,1] to our height range
	var combined := base_height * NOISE_PARAMS.terrain_scale + detail * NOISE_PARAMS.detail_scale
	var remapped := lerpf(TERRAIN_HEIGHT_RANGE.x, TERRAIN_HEIGHT_RANGE.y, (combined + 1.0) / 2.0)
	
	return remapped

func generate_stages(chunk: Node3D, chunk_coords: Vector2i) -> void:
	var num_stages := randi_range(STAGES_PER_CHUNK.min, STAGES_PER_CHUNK.max)
	var placed_stages: Array[Vector3] = []
	
	# Create a grid of potential positions
	var grid_size := 5
	var grid_steps := CHUNK_SIZE / grid_size
	var potential_positions := []
	
	for x in range(grid_size):
		for z in range(grid_size):
			var pos := Vector3(
				x * grid_steps + randf_range(-grid_steps/4, grid_steps/4),
				0,
				z * grid_steps + randf_range(-grid_steps/4, grid_steps/4)
			)
			potential_positions.append(pos)
	
	# Shuffle the potential positions
	potential_positions.shuffle()
	
	# Try to place stages at potential positions
	var stages_placed := 0
	for pos in potential_positions:
		if stages_placed >= num_stages:
			break
			
		var encounter_type := select_encounter_type()
		
		if is_valid_stage_position(pos, placed_stages):
			var world_pos :Vector3 = pos + Vector3(chunk_coords.x * CHUNK_SIZE, 0, chunk_coords.y * CHUNK_SIZE)
			pos.y = get_height_at_point(world_pos)
			
			var stage := create_stage(pos, encounter_type)
			if stage:
				chunk.add_child(stage)
				placed_stages.append(pos)
				stages_placed += 1
				stage_created.emit(stage, StringName(encounter_type))

func spawn_scannable_objects(chunk: Node3D, chunk_coords: Vector2i) -> void:
	var num_objects := randi_range(
		SCANNABLE_SPAWN_CONFIG.per_chunk.min, 
		SCANNABLE_SPAWN_CONFIG.per_chunk.max
	)
	
	var placed_positions: Array[Vector3] = []
	var attempts := 0
	var max_attempts := num_objects * 4  # Prevent infinite loops
	
	while placed_positions.size() < num_objects and attempts < max_attempts:
		var pos := Vector3(
			randf_range(0, CHUNK_SIZE),
			0,
			randf_range(0, CHUNK_SIZE)
		)
		
		# Check minimum spacing
		var valid_position := true
		for placed in placed_positions:
			if pos.distance_to(placed) < SCANNABLE_SPAWN_CONFIG.min_spacing:
				valid_position = false
				break
		
		if valid_position:
			var world_pos := pos + Vector3(
				chunk_coords.x * CHUNK_SIZE,
				0,
				chunk_coords.y * CHUNK_SIZE
			)
			
			# Set Y position based on terrain height
			pos.y = get_height_at_point(world_pos) + SCANNABLE_SPAWN_CONFIG.height_offset
			
			var object := scannable_object.instantiate()
			object.position = pos
			
			# Optional: Set random name/description from a pool if desired
			# object.object_name = get_random_object_name()
			# object.description = get_random_description()
			
			chunk.add_child(object)
			placed_positions.append(pos)
		
		attempts += 1

# Modify is_valid_stage_position to use type-specific spacing
func is_valid_stage_position(pos: Vector3, placed_stages: Array[Vector3]) -> bool:
	var encounter_type := select_encounter_type()
	var min_spacing: float = ENCOUNTER_TYPES[encounter_type].get("min_spacing", STAGES_PER_CHUNK.min_spacing)
	
	# Check distance from other stages
	for placed in placed_stages:
		if pos.distance_to(placed) < min_spacing:
			return false
	
	# Check terrain slope
	var world_pos := pos + Vector3(current_chunk.x * CHUNK_SIZE, 0, current_chunk.y * CHUNK_SIZE)
	if !is_terrain_flat_enough(world_pos, 3.0, 0.5):
		return false
		
	return true

# New function to check if terrain is flat enough for a stage
func is_terrain_flat_enough(center_pos: Vector3, radius: float, max_slope: float) -> bool:
	var center_height := get_height_at_point(center_pos)
	var check_points := 8
	
	for i in range(check_points):
		var angle := (2.0 * PI * i) / check_points
		var check_pos := center_pos + Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var height := get_height_at_point(check_pos)
		
		# If height difference is too large, terrain is not flat enough
		if abs(height - center_height) > max_slope:
			return false
	
	return true

func select_encounter_type() -> String:
	var roll := randf()
	var cumulative := 0.0
	
	for type in ENCOUNTER_TYPES:
		cumulative += ENCOUNTER_TYPES[type].weight
		if roll <= cumulative:
			return type
	
	return ENCOUNTER_TYPES.keys()[0]

# Update create_stage function with the new height offset
func create_stage(position: Vector3, encounter_type: String) -> Node3D:
	var stage := encounter_stage.instantiate() as Node3D
	if not stage:
		push_error("WorldGenerator: Failed to instantiate encounter_stage scene")
		return null
	
	# Name the stage
	stage.name = "EncounterStage_%s_%d_%d" % [
		encounter_type, 
		int(position.x), 
		int(position.z)
	]
	
	# Calculate base terrain height
	var terrain_height := get_height_at_point(position)
	position.y = terrain_height
	stage.position = position
	
	# Get surrounding terrain information
	var surrounding_info := analyze_surrounding_terrain(position, 3.0)
	
	# Use the explicit height offset from constants
	stage.position.y += STAGES_PER_CHUNK.height_offset
	
	# Setup the encounter with type-specific configurations
	if stage.has_method("setup_encounter"):
		var config := {
			"type": encounter_type,
			"terrain_height": terrain_height,
			"surrounding_height": surrounding_info.max_height,
			"avg_height": surrounding_info.avg_height,
			"slope_direction": surrounding_info.slope_direction
		}
		stage.setup_encounter(config)
	
	return stage

# New function to analyze surrounding terrain
func analyze_surrounding_terrain(pos: Vector3, radius: float = 3.0) -> Dictionary:
	var heights := []
	var positions := []
	var steps := 8  # Check 8 points around the position
	
	for i in range(steps):
		var angle := (2.0 * PI * i) / steps
		var check_pos := pos + Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var height := get_height_at_point(check_pos)
		heights.append(height)
		positions.append(check_pos)
	
	# Calculate average and find max height
	var sum := 0.0
	var max_height : float = heights[0]
	var min_height : float = heights[0]
	
	for h in heights:
		sum += h
		max_height = max(max_height, h)
		min_height = min(min_height, h)
	
	var avg_height := sum / heights.size()
	
	# Determine slope direction (if any)
	var slope_direction := Vector3.ZERO
	if max_height - min_height > 0.1:  # If there's a significant slope
		var highest_idx := heights.find(max_height)
		var lowest_idx := heights.find(min_height)
		if highest_idx >= 0 and lowest_idx >= 0:
			var highest_pos : Vector3 = positions[highest_idx]
			var lowest_pos : Vector3 = positions[lowest_idx]
			slope_direction = (highest_pos - lowest_pos).normalized()
	
	return {
		"max_height": max_height,
		"min_height": min_height,
		"avg_height": avg_height,
		"slope_direction": slope_direction
	}

func check_chunks(player_pos: Vector3) -> void:
	current_chunk = get_chunk_coords(player_pos)
	
	# Generate surrounding chunks
	for x in range(-1, 2):
		for y in range(-1, 2):
			var check_coords := current_chunk + Vector2i(x, y)
			if not generated_chunks.has(check_coords):
				generate_chunk(check_coords)
	
	# Clean up distant chunks
	var chunks_to_remove: Array[Vector2i] = []
	for coords in generated_chunks:
		if abs(coords.x - current_chunk.x) > 1 or abs(coords.y - current_chunk.y) > 1:
			chunks_to_remove.append(coords)
	
	for coords in chunks_to_remove:
		if generated_chunks[coords].is_inside_tree():
			generated_chunks[coords].queue_free()
		generated_chunks.erase(coords)

func _exit_tree() -> void:
	# Clean up noise resources
	if noise:
		noise.free()
	if detail_noise:
		detail_noise.free()
		
	# Clean up chunks
	for chunk in generated_chunks.values():
		if is_instance_valid(chunk) and chunk.is_inside_tree():
			chunk.queue_free()
	generated_chunks.clear()
