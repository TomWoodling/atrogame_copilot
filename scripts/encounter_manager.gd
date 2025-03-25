# encounter_manager.gd
extends Node

signal encounter_started(npc: NPController)
signal encounter_completed(npc: NPController)
signal dialog_started(dialog: DialogContainer)
signal dialog_completed
signal encounter_progressed(step: String, data: Dictionary)

enum ChallengeType { 
	NONE = -1,
	COLLECTION, 
	PLATFORMING, 
	TIMED_TASK, 
	PUZZLE 
}

var current_npc: NPController = null
var is_encounter_active: bool = false
var current_dialog: DialogContainer
var current_encounter_resource: EncounterResource = null

# Reference to Challenge Manager child node
@onready var challenge_manager = $challenge_manager

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

func start_dialog(dialog: DialogContainer) -> void:
	current_dialog = dialog
	HUDManager.show_dialog(dialog)
	emit_signal("dialog_started", dialog)

func on_dialog_completed() -> void:
	emit_signal("dialog_completed")
	
	# If we have an active encounter resource, progress through its steps
	if current_encounter_resource:
		# Check if there are challenges in the encounter resource
		if current_encounter_resource.challenges and current_encounter_resource.challenges.size() > 0:
			# Start first/next challenge using Challenge Manager
			var next_challenge = current_encounter_resource.challenges[0]
			challenge_manager.start_challenge(next_challenge)
		else:
			# No challenges, complete the encounter
			complete_encounter()

func complete_encounter() -> void:
	if not is_encounter_active:
		return
	
	# Cleanup message
	HUDManager.show_message({
		"text": "Encounter complete",
		"color": Color.GREEN,
		"duration": 1.0
	})
	
	# Reset NPC interaction
	if current_npc:
		current_npc.on_interaction_completed()
		current_npc = null
	
	is_encounter_active = false
	current_encounter_resource = null
	
	# Return to NORMAL gameplay state when encounter is fully complete
	GameManager._set_gameplay_state(GameManager.GameplayState.NORMAL)
	
	emit_signal("encounter_completed", current_npc)

# Load and manage encounter resources (unchanged from previous version)
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

# Existing helper methods
func get_encounter(encounter_id: String) -> EncounterResource:
	return encounter_registry.get(encounter_id)

func find_npc_by_id(npc_id: String) -> NPController:
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc is NPController and npc.npc_id == npc_id:
			return npc
	return null

# Encounter registry to store available encounters
var encounter_registry = {}
