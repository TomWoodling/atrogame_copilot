extends Node3D

signal stage_created(stage: Node3D, encounter_type: StringName)

# Terrain Generation Constants
const CHUNK_SIZE: int = 100
const TERRAIN_HEIGHT_RANGE: Vector2 = Vector2(-5.0, 5.0)
const NOISE_PARAMS = {
	"frequency": 0.005,
	"terrain_scale": 10.0,
	"detail_scale": 2.0
}

# Stage/Encounter Generation Constants
const STAGES_PER_CHUNK = {
	"min": 1,
	"max": 3,
	"min_spacing": 20.0
}

# Encounter type weights and configurations
const ENCOUNTER_TYPES = {
	"collection": { "weight": 0.4 },
	"npc": { "weight": 0.3 },
	"challenge": { "weight": 0.3 }
}

# Internal state
var noise: FastNoiseLite
var detail_noise: FastNoiseLite
var generated_chunks: Dictionary = {}
var current_chunk: Vector2i
var player: Node3D

@onready var encounter_stage: PackedScene = preload("res://scenes/stages/encounter_stage.tscn")

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
		generated_chunks[chunk_coords] = chunk
	else:
		chunk.queue_free()
		push_error("WorldGenerator: Failed to generate terrain for chunk %s" % chunk_coords)

func generate_terrain_mesh(chunk_coords: Vector2i) -> MeshInstance3D:
	var st := SurfaceTool.new()
	var plane_mesh := PlaneMesh.new()
	
	# Added one extra vertex on each side to avoid seams between chunks
	plane_mesh.size = Vector2(CHUNK_SIZE + 1, CHUNK_SIZE + 1)
	plane_mesh.subdivide_width = 32
	plane_mesh.subdivide_depth = 32
	
	var mesh_arrays := plane_mesh.get_mesh_arrays()
	if mesh_arrays.is_empty():
		push_error("WorldGenerator: Failed to get mesh arrays from plane mesh")
		return null
		
	var vertices: PackedVector3Array = mesh_arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = mesh_arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = mesh_arrays[Mesh.ARRAY_INDEX]
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Apply height to vertices
	for i in vertices.size():
		var vertex := vertices[i]
		var world_pos := vertex + Vector3(chunk_coords.x * CHUNK_SIZE, 0, chunk_coords.y * CHUNK_SIZE)
		
		# Adjust position to account for the extra units in plane_mesh.size
		var local_pos = Vector3(
			vertex.x - 0.5,  # Adjust for the extra unit in width
			0,
			vertex.z - 0.5   # Adjust for the extra unit in depth
		)
		
		var modified_vertex := Vector3(
			local_pos.x,
			get_height_at_point(world_pos),
			local_pos.z
		)
		st.add_vertex(modified_vertex)
		st.set_uv(uvs[i])
	
	# Create triangles
	for i in range(0, indices.size(), 3):
		st.add_index(indices[i])
		st.add_index(indices[i + 1])
		st.add_index(indices[i + 2])
	
	st.generate_normals()
	st.generate_tangents()  # Added for better lighting/materials
	
	var terrain := MeshInstance3D.new()
	terrain.mesh = st.commit()
	
	# Create a simple material
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.7, 0.2)  # Green for grass
	terrain.material_override = material
	
	# Add collision
	var static_body := StaticBody3D.new()
	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = terrain.mesh.create_trimesh_shape()
	static_body.add_child(collision_shape)
	terrain.add_child(static_body)
	
	return terrain

func get_height_at_point(world_pos: Vector3) -> float:
	var base_height := noise.get_noise_2d(world_pos.x, world_pos.z)
	var detail := detail_noise.get_noise_2d(world_pos.x * 2.0, world_pos.z * 2.0)
	
	return (base_height * NOISE_PARAMS.terrain_scale + 
			detail * NOISE_PARAMS.detail_scale)

func generate_stages(chunk: Node3D, chunk_coords: Vector2i) -> void:
	var num_stages := randi_range(STAGES_PER_CHUNK.min, STAGES_PER_CHUNK.max)
	var placed_stages: Array[Vector3] = []
	
	for _i in range(num_stages):
		var encounter_type := select_encounter_type()
		var max_attempts := 10
		var attempts := 0
		
		while attempts < max_attempts:
			var pos := Vector3(
				randf_range(0, CHUNK_SIZE),
				0,
				randf_range(0, CHUNK_SIZE)
			)
			
			if is_valid_stage_position(pos, placed_stages):
				var world_pos := pos + Vector3(chunk_coords.x * CHUNK_SIZE, 0, chunk_coords.y * CHUNK_SIZE)
				pos.y = get_height_at_point(world_pos)
				
				var stage := create_stage(pos, encounter_type)
				if stage:
					chunk.add_child(stage)
					placed_stages.append(pos)
					stage_created.emit(stage, StringName(encounter_type))
				break
				
			attempts += 1

func is_valid_stage_position(pos: Vector3, placed_stages: Array[Vector3]) -> bool:
	for placed in placed_stages:
		if pos.distance_to(placed) < STAGES_PER_CHUNK.min_spacing:
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

func create_stage(position: Vector3, encounter_type: String) -> Node3D:
	var stage := encounter_stage.instantiate() as Node3D
	if not stage:
		push_error("WorldGenerator: Failed to instantiate encounter_stage scene")
		return null
		
	stage.position = position
	if stage.has_method("setup_encounter"):
		stage.setup_encounter(encounter_type)
	return stage

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
