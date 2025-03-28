# encounter_manager.gd (Refactored for Godot 4.3)
extends Node

## Remember to update the system that handles player 
## interaction to call request_interaction() and connect to the interaction_requested signal.
## Emitted when an encounter interaction flow begins.
signal encounter_started(npc: NPController, encounter_id: String)
## Emitted when an encounter interaction flow ends.
signal encounter_finished(npc: NPController, encounter_id: String)
## Emitted when an encounter presents a quest to the player (via dialog).
## QuestManager should listen to this to handle quest acceptance UI/logic.
signal quest_offered(quest_id: String, offering_npc: NPController)
## Emitted when a specific dialog sequence needs to be started for an NPC.
signal request_dialog_start(dialog_id: String, npc_speaker: NPController)

# --- State ---
var is_encounter_active: bool = false
var current_npc: NPController = null
var current_encounter_id: String = "" # ID of the active EncounterResource

# --- Dependencies (Assumed Autoloads/Singletons) ---
# @onready var DialogManager: Node # Autoload assumed
# @onready var QuestTrackingManager: Node # Autoload assumed (tracks quest completion status)
# @onready var GameManager: Node # Autoload assumed (handles game states like ENCOUNTER vs NORMAL)

# --- Encounter Resources ---
var encounter_registry: Dictionary = {} # Stores loaded EncounterResource definitions [encounter_id -> EncounterResource]

# --- Initialization ---

func _ready() -> void:
	load_encounter_resources()
	# Connect signals from other systems if needed
	# Example: DialogManager.dialog_completed.connect(_on_dialog_completed)
	# Example: QuestTrackingManager.quest_completed.connect(_on_quest_completed)

	# Find all NPCs and connect to their interaction signal
	for npc in get_tree().get_nodes_in_group("npcs"): # Add NPCs to "npcs" group
		if npc is NPController:
			if not npc.is_connected("interaction_requested", Callable(self, "_on_npc_interaction_requested")):
				npc.interaction_requested.connect(_on_npc_interaction_requested)
		else:
			push_warning("Node '%s' in group 'npcs' is not an NPController." % [npc.name if npc else "null"])


func load_encounter_resources(path: String = "res://resources/encounters") -> void:
	encounter_registry.clear()
	var dir = DirAccess.open(path)
	if not dir:
		push_error("EncounterManager: Failed to open encounters directory at '%s'" % path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			var resource_path = path.path_join(file_name)
			var encounter_res = load(resource_path) as EncounterResource
			if encounter_res:
				if encounter_registry.has(encounter_res.encounter_id):
					push_warning("EncounterManager: Duplicate encounter_id '%s' found in '%s'. Overwriting." % [encounter_res.encounter_id, resource_path])
				encounter_registry[encounter_res.encounter_id] = encounter_res
			else:
				push_warning("EncounterManager: Failed to load EncounterResource from '%s'." % resource_path)
		file_name = dir.get_next()
	print("EncounterManager: Loaded %d encounter resources." % encounter_registry.size())


# --- Public API ---

# Call this externally (e.g., from QuestManager) when a quest is completed
func report_quest_completion(completed_quest_id: String) -> void:
	# Find the encounter associated with this quest
	var completed_encounter: EncounterResource = null
	for encounter in encounter_registry.values():
		if encounter.associated_quest_id == completed_quest_id:
			completed_encounter = encounter
			break

	if not completed_encounter:
		print("EncounterManager: No encounter found associated with completed quest_id '%s'." % completed_quest_id)
		return

	# Find the relevant NPC (if they are currently loaded/active)
	var npc = find_npc_by_id(completed_encounter.offered_by_npc_id)
	if not npc:
		# NPC might not be in the scene. The completion dialog might need to be deferred
		# until the next interaction, or handled differently.
		print("EncounterManager: NPC '%s' for completed quest '%s' not found in current scene." % [completed_encounter.offered_by_npc_id, completed_quest_id])
		return

	# If an encounter is already active with THIS npc, wait? Or override? Let's end current first.
	if is_encounter_active and current_npc == npc:
		end_encounter() # End potential generic chat before starting completion dialog

	# If encounter system is free, start the completion dialog flow
	if not is_encounter_active and not completed_encounter.completion_dialog_id.is_empty():
		print("EncounterManager: Starting completion dialog '%s' for quest '%s' with NPC '%s'." % [completed_encounter.completion_dialog_id, completed_quest_id, npc.npc_id])
		_start_encounter_flow(npc, completed_encounter.encounter_id, completed_encounter.completion_dialog_id, true) # Mark as completion dialog


# --- Signal Handlers ---

# Called when an NPController's interaction_requested signal is emitted
func _on_npc_interaction_requested(npc: NPController) -> void:
	if is_encounter_active:
		print("EncounterManager: Interaction requested with '%s', but another encounter is already active with '%s'. Ignoring." % [npc.npc_id, current_npc.npc_id])
		# Optionally provide feedback to the player (e.g., "NPC is busy")
		return

	# --- Core Encounter Selection Logic ---
	var chosen_encounter_id = _select_encounter_for_npc(npc)

	if not chosen_encounter_id.is_empty():
		var encounter_res = encounter_registry[chosen_encounter_id]
		# Start the main encounter flow
		_start_encounter_flow(npc, chosen_encounter_id, encounter_res.initial_dialog_id)
	else:
		# No specific encounter available. Check for post-completion dialogs.
		var post_completion_dialog_id = _get_post_completion_dialog(npc)
		if not post_completion_dialog_id.is_empty():
			_start_encounter_flow(npc, "", post_completion_dialog_id) # No specific encounter ID, just dialog
		else:
			# Fallback: Generic greeting or no interaction
			print("EncounterManager: No suitable encounter or post-completion dialog for NPC '%s'. Playing generic greeting." % npc.npc_id)
			npc.start_interaction_state()
			npc.play_greeting_animation()
			# Maybe a very short generic dialog bubble via HUDManager?
			# For simplicity, just end quickly or let animation play out.
			# We might immediately call end_encounter() or use a timer.
			var timer = get_tree().create_timer(1.5) # Let greeting animation play briefly
			await timer.timeout
			if npc.is_currently_interacting: # Check if state hasn't changed
				npc.end_interaction_state()


# Called by DialogManager when a dialog sequence finishes
# NOTE: You need to connect this signal: DialogManager.dialog_completed.connect(_on_dialog_completed)
func _on_dialog_completed(dialog_id: String) -> void:
	if not is_encounter_active or not current_npc:
		return # Dialog finished, but not part of a managed encounter

	print("EncounterManager: Dialog '%s' completed for NPC '%s'." % [dialog_id, current_npc.npc_id])

	var encounter_res = encounter_registry.get(current_encounter_id)

	# Was this the initial dialog of an encounter that offers a quest?
	if encounter_res and dialog_id == encounter_res.initial_dialog_id and not encounter_res.associated_quest_id.is_empty():
		print("EncounterManager: Offering quest '%s' via NPC '%s'." % [encounter_res.associated_quest_id, current_npc.npc_id])
		emit_signal("quest_offered", encounter_res.associated_quest_id, current_npc)
		# --- IMPORTANT ---
		# The QuestManager should now handle the player's response (Accept/Decline).
		# Depending on QuestManager's logic, it might:
		# 1. Start *another* dialog sequence (Accept/Decline confirmation).
		# 2. Directly signal back to EncounterManager if the encounter should end now (e.g., player declined).
		# 3. Simply log the quest as accepted and let the EncounterManager end the current interaction.

		# For this example, we assume the interaction ends after the offer.
		# QuestManager might start follow-up actions independently.
		end_encounter()

	# Was this a completion dialog?
	elif encounter_res and dialog_id == encounter_res.completion_dialog_id:
		print("EncounterManager: Quest '%s' completion dialog finished." % encounter_res.associated_quest_id)
		# Mark post-completion dialog as seen (if needed - logic depends on QuestTrackingManager)
		# QuestTrackingManager.mark_post_completion_dialog_seen(encounter_res.encounter_id) # Example
		end_encounter()

	# Was this a post-completion dialog?
	elif encounter_res and dialog_id == encounter_res.post_completion_dialog_id:
		print("EncounterManager: Post-completion dialog finished for encounter '%s'." % encounter_res.encounter_id)
		end_encounter()

	# Was this a generic dialog with no associated encounter?
	elif current_encounter_id.is_empty():
		print("EncounterManager: Generic dialog '%s' finished." % dialog_id)
		end_encounter()

	else:
		# Dialog finished, but doesn't match expected flows (e.g., intermediate dialog step)
		# Decide whether to end the encounter or wait for further signals/events
		print("EncounterManager: Dialog '%s' finished, but no specific follow-up action defined. Ending encounter." % dialog_id)
		end_encounter()


# --- Internal Logic ---

func _start_encounter_flow(npc: NPController, encounter_id: String, dialog_id: String, is_completion_dialog: bool = false) -> void:
	if is_encounter_active:
		push_warning("EncounterManager: Tried to start encounter flow for '%s' while encounter with '%s' is active!" % [npc.npc_id, current_npc.npc_id])
		return

	is_encounter_active = true
	current_npc = npc
	current_encounter_id = encounter_id # Can be empty for generic dialogs

	# Notify GameManager, HUD, etc.
	# GameManager._set_gameplay_state(GameManager.GameplayState.ENCOUNTER) # Example
	print("EncounterManager: Starting encounter '%s' with NPC '%s'." % [encounter_id if not encounter_id.is_empty() else "Generic Dialog", npc.npc_id])

	npc.start_interaction_state() # Tell NPC to visually start interacting

	# Request DialogManager to show the dialog
	if not dialog_id.is_empty():
		emit_signal("request_dialog_start", dialog_id, npc)
	else:
		# No dialog? Maybe just an animation? End the encounter quickly?
		push_warning("EncounterManager: Encounter '%s' started with no initial dialog_id." % encounter_id)
		end_encounter() # End immediately if no dialog specified
		return

	emit_signal("encounter_started", npc, encounter_id)


func end_encounter() -> void:
	if not is_encounter_active:
		return

	print("EncounterManager: Ending encounter '%s' with NPC '%s'." % [current_encounter_id if not current_encounter_id.is_empty() else "Generic Dialog", current_npc.npc_id])

	var ended_encounter_id = current_encounter_id

	if current_npc:
		current_npc.end_interaction_state() # Tell NPC to return to idle

	# Reset state *before* emitting signal, in case signal handler tries to start a new encounter
	is_encounter_active = false
	var previous_npc = current_npc
	current_npc = null
	current_encounter_id = ""

	# Notify other systems
	# GameManager._set_gameplay_state(GameManager.GameplayState.NORMAL) # Example

	emit_signal("encounter_finished", previous_npc, ended_encounter_id)


# Determines the best available encounter for a given NPC
func _select_encounter_for_npc(npc: NPController) -> String:
	var potential_encounters: Array[EncounterResource] = []

	# Filter registry for encounters offered by this NPC type/ID
	for encounter in encounter_registry.values():
		if encounter.offered_by_npc_id == npc.npc_id:
			potential_encounters.append(encounter)

	if potential_encounters.is_empty():
		return "" # No encounters defined for this NPC

	# Further filter based on conditions (completion status, prerequisites, etc.)
	var valid_encounters: Array[EncounterResource] = []
	for encounter in potential_encounters:
		# Check one-time completion (requires QuestTrackingManager)
		var quest_id = encounter.associated_quest_id
		if encounter.one_time_only and not quest_id.is_empty():
			# Assumes QuestTrackingManager has a method like this:
			# if QuestTrackingManager.is_quest_completed(quest_id):
			#    continue # Skip already completed one-time quests
			pass # Placeholder for completion check

		# Check other prerequisites (requires GameManager, PlayerStats, etc.)
		# Example: if encounter.min_player_level > PlayerStats.level: continue
		# Example: if not QuestTrackingManager.are_flags_met(encounter.prerequisite_flags): continue
		# ... add more checks as needed ...

		valid_encounters.append(encounter)

	if valid_encounters.is_empty():
		return "" # No currently valid encounters

	# Selection Strategy (can be customized)
	# 1. Priority-based (if encounters have a priority field)
	# 2. Random selection
	# 3. Sequential (if designed that way)

	# Example: Simple random selection
	randomize()
	var chosen_encounter = valid_encounters[randi() % valid_encounters.size()]
	return chosen_encounter.encounter_id


# Check if there's a relevant post-completion dialog for this NPC
func _get_post_completion_dialog(npc: NPController) -> String:
	# This requires knowledge of which quests the player *has* completed
	# that were *offered* by this NPC.
	# Assume QuestTrackingManager provides this info.

	# Example: Get completed quests related to this NPC
	# var completed_quest_ids = QuestTrackingManager.get_completed_quests_by_npc(npc.npc_id) # Hypothetical function

	# Iterate through completed quests to find corresponding encounters and check for post-completion dialog
	# for quest_id in completed_quest_ids:
	#    var encounter = find_encounter_by_quest_id(quest_id) # Need helper
	#    if encounter and not encounter.post_completion_dialog_id.is_empty():
	#        # Check if this post-completion dialog has already been seen
	#        # if not QuestTrackingManager.has_seen_post_completion_dialog(encounter.encounter_id): # Hypothetical
	#        #    return encounter.post_completion_dialog_id
	#        pass # Placeholder

	# Simplified: Return empty for now. Implement with QuestTrackingManager integration.
	return ""


# --- Utility ---

func find_npc_by_id(npc_id: String) -> NPController:
	for node in get_tree().get_nodes_in_group("npcs"):
		var npc = node as NPController
		if npc and npc.npc_id == npc_id:
			return npc
	return null

func find_encounter_by_quest_id(quest_id: String) -> EncounterResource:
	if quest_id.is_empty(): return null
	for encounter in encounter_registry.values():
		if encounter.associated_quest_id == quest_id:
			return encounter
	return null
