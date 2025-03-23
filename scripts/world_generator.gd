extends Node3D

# Add Scannable Selector
@onready var scannable_selector: ScannableSelector = ScannableSelector.new()

# Terrain Generation Constants
const CHUNK_SIZE: int = 100
const TERRAIN_HEIGHT_RANGE: Vector2 = Vector2(-4.0, 4.5)
const NOISE_PARAMS = {
	"frequency": 0.005,
	"terrain_scale": 10.0,
	"detail_scale": 2.0
}

const SCANNABLE_SPAWN_CONFIG = {
	"per_chunk": {
		"min": 2,
		"max": 4
	},
	"min_spacing": 15.0,  # Minimum distance between scannable objects
	"height_offset": 0.1   # How far above terrain to spawn
}

# Internal state
var noise: FastNoiseLite
var detail_noise: FastNoiseLite
var generated_chunks: Dictionary = {}
var current_chunk: Vector2i
var player: Node3D

@onready var scannable_object: PackedScene = preload("res://scenes/objects/basic_tree.tscn")

func _ready() -> void:
	# Initialize the scannable selector
	add_child(scannable_selector)
	
	setup_noise()
	await get_tree().process_frame
	initialize_world()

func get_terrain_height_range() -> Vector2:
	return TERRAIN_HEIGHT_RANGE

func _physics_process(_delta: float) -> void:
	if not player:
		return
		
	var player_chunk := get_chunk_coords(player.global_position)
	if current_chunk != player_chunk:
		check_chunks(player.global_position)

func setup_noise() -> void:
	# Main terrain noise
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = NOISE_PARAMS.frequency
	
	# Detail noise for added variation
	detail_noise = FastNoiseLite.new()
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
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
		spawn_scannable_objects(chunk, chunk_coords)
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
			var terrain_height = get_height_at_point(world_pos)
			pos.y = terrain_height + SCANNABLE_SPAWN_CONFIG.height_offset
			
			# Get appropriate scannable for this location
			var object_scene = scannable_selector.get_scannable_for_location(world_pos, terrain_height)
			var object = object_scene.instantiate()
			
			object.position = pos
			chunk.add_child(object)
			placed_positions.append(pos)
		
		attempts += 1

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
