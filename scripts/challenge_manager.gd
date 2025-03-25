# challenge_manager.gd
extends Node

signal challenge_progress_updated(current_count: int, total_count: int)
signal challenge_completed(success: bool)

# Current active challenge data
var current_challenge_type: String = ""
var challenge_parameters: Dictionary = {}
var collected_items: Array = []
var challenge_objects: Array = []
var destination_marker: Node3D = null

# Reference to the challenge generator
@onready var challenge_generator = $"../challenge_generator"

# Initialize a new challenge
func start_challenge(challenge_resource: ChallengeResource) -> bool:
	# Reset previous challenge state
	_reset_challenge_state()
	
	# Validate and set up challenge
	current_challenge_type = challenge_resource.type
	challenge_parameters = challenge_resource.parameters.duplicate()
	
	# Add type-specific parameters from the resource
	match current_challenge_type:
		"COLLECTION":
			return _setup_collection_challenge(challenge_resource)
		"PLATFORMING":
			return _setup_platforming_challenge(challenge_resource)
		_:
			push_error("Unsupported challenge type: " + current_challenge_type)
			return false

# Setup for collection challenge
func _setup_collection_challenge(challenge_resource: ChallengeResource) -> bool:
	# Determine center position (NPC or player)
	var center_position = _get_challenge_center_position()
	
	# Add center position to parameters
	challenge_parameters["center_position"] = center_position
	
	# Additional parameters from resource
	challenge_parameters["count"] = challenge_resource.collection_count
	challenge_parameters["spawn_radius"] = challenge_resource.spawn_radius
	
	# Validate parameters
	if not challenge_generator.validate_challenge_params("COLLECTION", challenge_parameters):
		push_error("Invalid collection challenge parameters")
		return false
	
	# Generate collectible items
	challenge_objects = challenge_generator.generate_collection_challenge(challenge_parameters)
	
	# Add items to scene and connect signals
	for item in challenge_objects:
		get_tree().current_scene.add_child(item)
		item.connect("collected", _on_item_collected)
	
	return true

# Setup for platforming challenge
func _setup_platforming_challenge(challenge_resource: ChallengeResource) -> bool:
	# Determine destination position
	var dest_pos = _calculate_destination_position(challenge_resource)
	
	# Prepare parameters
	challenge_parameters["destination_position"] = dest_pos
	
	# Validate parameters
	if not challenge_generator.validate_challenge_params("PLATFORMING", challenge_parameters):
		push_error("Invalid platforming challenge parameters")
		return false
	
	# Generate destination marker
	destination_marker = challenge_generator.generate_destination_marker(challenge_parameters)
	get_tree().current_scene.add_child(destination_marker)
	destination_marker.connect("reached", _on_destination_reached)
	
	return true

# Handle item collection
func _on_item_collected(item_id: String) -> void:
	collected_items.append(item_id)
	
	# Emit progress update
	emit_signal("challenge_progress_updated", 
		collected_items.size(), 
		challenge_parameters.get("count", 1)
	)
	
	# Check if challenge is complete
	if collected_items.size() >= challenge_parameters.get("count", 1):
		complete_challenge(true)

# Handle destination reached
func _on_destination_reached() -> void:
	complete_challenge(true)

# Complete the challenge
func complete_challenge(success: bool) -> void:
	emit_signal("challenge_completed", success)
	
	# Clean up challenge objects
	_cleanup_challenge_objects()

# Reset challenge state
func _reset_challenge_state() -> void:
	current_challenge_type = ""
	challenge_parameters.clear()
	collected_items.clear()
	
	# Remove any existing challenge objects
	_cleanup_challenge_objects()

# Clean up challenge objects
func _cleanup_challenge_objects() -> void:
	# Remove collectible items
	for item in challenge_objects:
		if is_instance_valid(item):
			item.queue_free()
	challenge_objects.clear()
	
	# Remove destination marker
	if is_instance_valid(destination_marker):
		destination_marker.queue_free()
	destination_marker = null

# Calculate destination position for platforming challenges
func _calculate_destination_position(challenge_resource: ChallengeResource) -> Vector3:
	var dest_pos = challenge_resource.destination_position
	
	# If using NPC-relative positioning
	if challenge_resource.use_npc_relative_position:
		var current_npc = EncounterManager.current_npc
		if current_npc:
			dest_pos = current_npc.global_position + challenge_resource.position_offset
	
	return dest_pos

# Get center position for challenge (NPC or player)
func _get_challenge_center_position() -> Vector3:
	var current_npc = EncounterManager.current_npc
	return current_npc.global_position if current_npc else GameManager.player.global_position
