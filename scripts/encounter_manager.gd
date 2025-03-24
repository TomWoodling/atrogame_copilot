# encounter_manager.gd (updated)
extends Node

signal encounter_started(npc: NPController)
signal challenge_started(type: ChallengeType, parameters: Dictionary)
signal challenge_completed(success: bool)
signal encounter_completed(npc: NPController)
signal dialog_started(dialog: DialogContainer)
signal dialog_completed
signal encounter_progressed(step: String, data: Dictionary)

enum ChallengeType { 
	NONE = -1,  # Adding a NONE state to represent no active challenge
	COLLECTION, # Collect X items within constraints
	PLATFORMING, # Reach a destination within constraints
	TIMED_TASK, # Complete an action within time limit
	PUZZLE # Solve a environmental puzzle
}

var active_challenge: ChallengeType = ChallengeType.NONE

var current_npc: NPController = null
var challenge_parameters: Dictionary = {}
var is_encounter_active: bool = false
var is_challenge_active: bool = false
var current_dialog: DialogContainer
var collected_items = []

var encounter_registry = {}
var challenge_registry = {}

var current_encounter_resource: EncounterResource = null
var current_challenge_index: int = 0
var completed_challenges: Array = []

func start_encounter(npc: NPController, dialog_id: String = "") -> void:
	if is_encounter_active:
		return
	
	current_npc = npc
	is_encounter_active = true
	
	# Notify the GameManager to switch to ENCOUNTER state
	GameManager._set_gameplay_state(GameManager.GameplayState.ENCOUNTER)
	
	# Start with NPC dialog
	if npc:
		npc.on_interaction_started()
		
	# Get dialog from dialog manager
	if dialog_id:
		var dialog = DialogManager.get_dialog(dialog_id)
		if dialog:
			start_dialog(dialog)
	
	emit_signal("encounter_started", npc)

func start_challenge(type: ChallengeType, parameters: Dictionary) -> void:
	if not is_encounter_active or is_challenge_active:
		return
	
	active_challenge = type
	challenge_parameters = parameters
	is_challenge_active = true
	
	# Reset collected items for new challenge
	collected_items.clear()
	
	emit_signal("challenge_started", type, parameters)
	
	# Show challenge instructions
	HUDManager.show_message({
		"text": "Challenge started: " + _get_challenge_description(type, parameters),
		"color": Color(0.9, 0.7, 0.2),
		"duration": 3.0
	})

# Start a challenge from a resource
func start_challenge_from_resource(challenge_resource: ChallengeResource) -> void:
	var type = _get_challenge_type_from_string(challenge_resource.type)
	var params = challenge_resource.parameters.duplicate()
	
	# Add type-specific parameters
	match type:
		ChallengeType.COLLECTION:
			params["count"] = challenge_resource.collection_count
			params["items"] = challenge_resource.items_to_collect
			if challenge_resource.time_limit > 0:
				params["time_limit"] = challenge_resource.time_limit
				
		ChallengeType.PLATFORMING:
			var dest_pos = challenge_resource.destination_position
			if challenge_resource.use_npc_relative_position and current_npc:
				dest_pos = current_npc.global_position + challenge_resource.position_offset
			params["destination"] = dest_pos
			
		ChallengeType.PUZZLE:
			params["puzzle_id"] = challenge_resource.puzzle_id
			
		ChallengeType.TIMED_TASK:
			params["time_limit"] = challenge_resource.time_limit
	
	# Start the challenge
	start_challenge(type, params)

# Challenge completion handling
func complete_challenge(success: bool) -> void:
	if not is_challenge_active:
		return
	
	is_challenge_active = false
	active_challenge = ChallengeType.NONE
	
	# Show completion message
	HUDManager.show_message({
		"text": "Challenge " + ("completed!" if success else "failed!"),
		"color": Color.GREEN if success else Color.RED,
		"duration": 2.0
	})
	
	emit_signal("challenge_completed", success)
	
	# Handle progression
	if current_encounter_resource:
		if success:
			completed_challenges.append(current_challenge_index)
			current_challenge_index += 1
			
			# Show success dialog if specified
			var challenge = current_encounter_resource.challenges[current_challenge_index - 1]
			if not challenge.success_dialog_id.is_empty():
				var dialog = DialogManager.get_dialog(challenge.success_dialog_id)
				if dialog:
					start_dialog(dialog)
					return
		else:
			# Handle failure - show dialog or allow retry
			var challenge = current_encounter_resource.challenges[current_challenge_index]
			if not challenge.failure_dialog_id.is_empty():
				var dialog = DialogManager.get_dialog(challenge.failure_dialog_id)
				if dialog:
					start_dialog(dialog)
					return
			elif challenge.allow_retry:
				# Wait for retry action from player
				return
		
		# Progress to next step automatically
		on_dialog_completed()  # Reuse logic to progress

func complete_encounter() -> void:
	if not is_encounter_active:
		return
	
	# Clean up any active challenge if it exists
	if is_challenge_active:
		complete_challenge(false)
	
	# Message to player
	HUDManager.show_message({
		"text": "Encounter complete",
		"color": Color.GREEN,
		"duration": 1.0
	})
	
	if current_npc:
		current_npc.on_interaction_completed()
		current_npc = null
	
	is_encounter_active = false
	active_challenge = ChallengeType.NONE  # Ensure challenge is reset
	challenge_parameters = {}  # Clear parameters too
	
	# Return to NORMAL gameplay state when encounter is fully complete
	GameManager._set_gameplay_state(GameManager.GameplayState.NORMAL)
	
	emit_signal("encounter_completed", current_npc)

func start_dialog(dialog: DialogContainer) -> void:
	current_dialog = dialog
	HUDManager.show_dialog(dialog)
	emit_signal("dialog_started", dialog)

func on_dialog_mood_changed(mood: String) -> void:
	# Update NPC mood if one is active
	if current_npc:
		match mood:
			"positive":
				current_npc.on_mood_change(true)
			"negative":
				current_npc.on_mood_change(false)
			_: # neutral or anything else
				current_npc.get_random_talk_animation()

# When dialog completes, check if we should start a challenge
func on_dialog_completed() -> void:
	emit_signal("dialog_completed")
	
	# If we have an active encounter, progress to next phase
	if current_encounter_resource and not is_challenge_active:
		# Start the first/next challenge if available
		if current_challenge_index < current_encounter_resource.challenges.size():
			var challenge = current_encounter_resource.challenges[current_challenge_index]
			start_challenge_from_resource(challenge)
		elif completed_challenges.size() > 0:
			# All challenges completed, show completion dialog
			var dialog = DialogManager.get_dialog(current_encounter_resource.completion_dialog_id)
			if dialog:
				start_dialog(dialog)
			else:
				complete_encounter()
		else:
			# No challenges to complete
			complete_encounter()

func _get_challenge_description(type: ChallengeType, parameters: Dictionary) -> String:
	match type:
		ChallengeType.COLLECTION:
			return "Collect " + str(parameters.get("count", 0)) + " " + parameters.get("item_name", "items")
		ChallengeType.PLATFORMING:
			return "Reach the destination" + (" in " + str(parameters.get("time_limit", 0)) + " seconds" if parameters.has("time_limit") else "")
		ChallengeType.TIMED_TASK:
			return "Complete the task in " + str(parameters.get("time_limit", 30)) + " seconds"
		ChallengeType.PUZZLE:
			return "Solve the environmental puzzle"
		_:
			return "Complete the challenge"

# NEW FUNCTION: Convert string type to enum
func _get_challenge_type_from_string(type_string: String) -> ChallengeType:
	match type_string.to_lower():
		"collection":
			return ChallengeType.COLLECTION
		"platforming":
			return ChallengeType.PLATFORMING
		"timed_task":
			return ChallengeType.TIMED_TASK
		"puzzle":
			return ChallengeType.PUZZLE
		_:
			return ChallengeType.NONE

func load_encounter_resources() -> void:
	var dir = DirAccess.open("res://resources/encounters")
	if not dir:
		push_error("Failed to open encounters directory")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var encounter = load("res://resources/encounters/" + file_name)
			if encounter is EncounterResource:
				encounter_registry[encounter.encounter_id] = encounter
		
		file_name = dir.get_next()

# Get encounter by ID
func get_encounter(encounter_id: String) -> EncounterResource:
	return encounter_registry.get(encounter_id)
	
# Start encounter from resource
func start_encounter_by_id(encounter_id: String, npc: NPController = null) -> void:
	var encounter_resource = get_encounter(encounter_id)
	if not encounter_resource:
		push_error("Encounter not found: " + encounter_id)
		return
	
	# Set up the encounter
	var npc_to_use = npc if npc else find_npc_by_id(encounter_resource.npc_id)
	start_encounter(npc_to_use, encounter_resource.initial_dialog_id)
	
	# Store the current encounter resource for later use
	current_encounter_resource = encounter_resource

# NEW FUNCTION: Find NPC by ID
func find_npc_by_id(npc_id: String) -> NPController:
	# Look for NPCs in the current scene
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc is NPController and npc.npc_id == npc_id:
			return npc
	return null

# Set up physical elements of a challenge
func setup_challenge_stage(challenge_type: ChallengeType, params: Dictionary) -> void:
	match challenge_type:
		ChallengeType.COLLECTION:
			_setup_collection_stage(params)
		ChallengeType.PLATFORMING:
			_setup_platforming_stage(params)
		ChallengeType.PUZZLE:
			_setup_puzzle_stage(params)
		ChallengeType.TIMED_TASK:
			_setup_timed_task_stage(params)

# Collection challenge setup
func _setup_collection_stage(params: Dictionary) -> void:
	var count = params.get("count", 1)
	var items = params.get("items", [])
	var spawn_radius = params.get("spawn_radius", 10.0)
	
	# Get spawn center (use NPC position or player position)
	var center_position = current_npc.global_position if current_npc else GameManager.player.global_position
	
	# Spawn collectible items
	for i in range(count):
		var random_position = center_position + Vector3(
			randf_range(-spawn_radius, spawn_radius),
			0, # Keep on ground level
			randf_range(-spawn_radius, spawn_radius)
		)
		
		# Create collectible
		var item_id = items[randi() % items.size()] if items.size() > 0 else "generic_item"
		var collectible = preload("res://scenes/challenge_collectable.tscn").instantiate()
		collectible.item_id = item_id
		
		# Fixed signal connection for Godot 4.x
		collectible.collected.connect(_on_item_collected)
		
		# Add to scene
		get_tree().current_scene.add_child(collectible)
		collectible.global_position = random_position

func _on_item_collected(item_id: String) -> void:
	collected_items.append(item_id)
	
	# Show progress
	var required_count = challenge_parameters.get("count", 1)
	HUDManager.show_message({
		"text": "Collected " + str(collected_items.size()) + "/" + str(required_count),
		"color": Color(0.2, 0.7, 0.9),
		"duration": 1.0
	})
	
	# Check if challenge is complete
	if collected_items.size() >= required_count:
		complete_challenge(true)

# Placeholder functions with proper typing and empty bodies
func _setup_platforming_stage(params: Dictionary) -> void:
	pass

func _setup_puzzle_stage(params: Dictionary) -> void:
	pass

func _setup_timed_task_stage(params: Dictionary) -> void:
	pass
