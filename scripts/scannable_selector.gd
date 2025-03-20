# scannable_selector.gd
extends Node
class_name ScannableSelector

# Define biome types or terrain features that affect what can spawn
enum BiomeType {FOREST, DESERT, MOUNTAIN, PLAINS}

# Scannable object registry with their scene paths and spawn rules
const SCANNABLE_REGISTRY = {
	"tree": {
		"scene_path": "res://scenes/objects/basic_tree.tscn",
		"weight": 0.5,
		"biome_modifiers": {
			BiomeType.FOREST: 2.0,  # More likely in forests
			BiomeType.DESERT: 0.1   # Rare in deserts
		},
		"min_elevation": -1.0,
		"max_elevation": 2.0
	},
	"crystal": {
		"scene_path": "res://scenes/objects/crystal_formation.tscn",
		"weight": 0.3,
		"biome_modifiers": {
			BiomeType.MOUNTAIN: 1.5
		},
		"min_elevation": 0.5,  # Only spawns above certain height
		"max_elevation": 2.5
	},
	"artifact": {
		"scene_path": "res://scenes/objects/alien_artifact.tscn",
		"weight": 0.1,  # Rare
		"biome_modifiers": {},  # No biome preference
		"min_elevation": -2.0,
		"max_elevation": 2.0
	}
}

# Cache loaded scenes to avoid repeated loading
var _scene_cache = {}

func _ready() -> void:
	# Preload all scannable scenes to improve performance
	for item_id in SCANNABLE_REGISTRY:
		var scene_path = SCANNABLE_REGISTRY[item_id].scene_path
		_scene_cache[item_id] = load(scene_path)

# Get appropriate scannable for a specific location
func get_scannable_for_location(world_pos: Vector3, terrain_height: float, biome_type: int = BiomeType.PLAINS) -> PackedScene:
	# Filter by elevation
	var valid_scannables = []
	var total_weight = 0.0
	
	for item_id in SCANNABLE_REGISTRY:
		var item = SCANNABLE_REGISTRY[item_id]
		
		# Check elevation constraints
		if terrain_height < item.min_elevation or terrain_height > item.max_elevation:
			continue
			
		# Calculate final weight with biome modifiers
		var final_weight = item.weight
		if item.biome_modifiers.has(biome_type):
			final_weight *= item.biome_modifiers[biome_type]
			
		if final_weight > 0:
			valid_scannables.append({
				"id": item_id,
				"weight": final_weight
			})
			total_weight += final_weight
	
	# If no valid scannables, return default tree
	if valid_scannables.size() == 0:
		return _scene_cache.get("tree", load("res://scenes/objects/basic_tree.tscn"))
	
	# Select random scannable based on weights
	var roll = randf() * total_weight
	var current_weight = 0.0
	
	for scannable in valid_scannables:
		current_weight += scannable.weight
		if roll <= current_weight:
			return _scene_cache[scannable.id]
	
	# Fallback to first valid scannable
	return _scene_cache[valid_scannables[0].id]

# Get biome type based on terrain data
func determine_biome_type(terrain_data: Dictionary) -> int:
	# This is where you'd implement biome determination based on:
	# - Elevation/height
	# - Noise values
	# - Location in the world
	# - Temperature/moisture (if you have those systems)
	
	# Simple example based on height:
	var height = terrain_data.get("height", 0.0)
	if height > 1.5:
		return BiomeType.MOUNTAIN
	elif height < -0.5:
		return BiomeType.DESERT
	elif height > 0.0 and height < 1.0:
		return BiomeType.FOREST
	else:
		return BiomeType.PLAINS
