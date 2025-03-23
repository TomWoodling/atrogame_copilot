# encounter_manager.gd (updated)
extends Node

signal encounter_started(type: EncounterType)
signal encounter_completed(type: EncounterType)
signal dialog_started(dialog: DialogContainer)
signal dialog_completed

enum EncounterType { INFO, COLLECTION, NPC }

# Store messages that can be reused throughout the game
const MESSAGES = {
	"tutorial_movement": "Use WASD to move and Space to jump",
	"tutorial_interact": "Press E to interact with objects",
	"low_oxygen": "Warning: Oxygen levels critical in this area!",
	"resource_rich": "Scanners detect valuable resources nearby"
}

var current_encounter: EncounterType = EncounterType.INFO
var is_encounter_active: bool = false
var current_dialog: DialogContainer

# Reference to the active NPC in a conversation (if any)
var active_npc: NPController = null

func start_encounter(type: EncounterType, custom_message: String = "", npc_reference = null) -> void:
	if is_encounter_active:
		return
	current_encounter = type
	is_encounter_active = true
	match type:
		EncounterType.INFO:
			_show_info_message(custom_message)
		EncounterType.NPC:
			_start_npc_encounter(custom_message, npc_reference)  # Pass NPC reference here
		EncounterType.COLLECTION:
			_start_collection_encounter()
	emit_signal("encounter_started", type)

func complete_encounter() -> void:
	if not is_encounter_active:
		return
	
	match current_encounter:
		EncounterType.COLLECTION:
			HUDManager.show_message({
				"text": "Item collected!",
				"color": Color.GREEN,
				"duration": 1.0
			})
		EncounterType.NPC:
			HUDManager.show_message({
				"text": "Conversation complete",
				"color": Color.GREEN,
				"duration": 1.0
			})
			
			# Reset active NPC reference
			active_npc = null
	
	is_encounter_active = false
	emit_signal("encounter_completed", current_encounter)
	current_encounter = EncounterType.INFO

func _show_info_message(message: String) -> void:
	# For simple messages, use the existing system
	if not ":" in message:
		HUDManager.show_message({
			"text": message if message else "This is the default message",
			"color": Color(0.9, 0.9, 0.2),
			"duration": 3.0
		})
		return
	
	# For dialog-formatted messages, use the dialog system
	var dialog = DialogContainer.new()
	dialog.dialog_id = "info_message"
	
	# Handle Speaker:Text format
	var parts = message.split(":", true, 1)
	if parts.size() >= 2:
		dialog.add_entry(parts[0].strip_edges(), parts[1].strip_edges())
	else:
		dialog.add_entry("", message)
		
	start_dialog(dialog)

func _start_npc_encounter(dialog_id: String, npc: NPController = null) -> void:
	# Store reference to active NPC
	active_npc = npc
	
	if active_npc:
		active_npc.on_interaction_started()
	
	# Get dialog from dialog manager
	var dialog = DialogManager.get_dialog(dialog_id)
	if dialog:
		start_dialog(dialog)
	else:
		# Fallback to simple message if dialog not found
		HUDManager.show_message({
			"text": "Hello, fellow astronaut!",
			"color": Color(0.2, 0.7, 0.9),
			"duration": 3.0
		})

func _start_collection_encounter() -> void:
	HUDManager.show_message({
		"text": "Valuable resource detected",
		"color": Color(0.2, 0.9, 0.2),
		"duration": 2.0
	})

func start_dialog(dialog: DialogContainer) -> void:
	current_dialog = dialog
	HUDManager.show_dialog(dialog)
	emit_signal("dialog_started", dialog)

func on_dialog_mood_changed(mood: String) -> void:
	# Update NPC mood if one is active
	if active_npc:
		match mood:
			"positive":
				active_npc.on_mood_change(true)
			"negative":
				active_npc.on_mood_change(false)
			_: # neutral or anything else
				active_npc.get_random_talk_animation()

func on_dialog_completed() -> void:
	# If this was part of an active encounter, complete it
	if is_encounter_active:
		complete_encounter()
	
	emit_signal("dialog_completed")

func report_mission_status(message: String) -> void:
	HUDManager.show_message({
		"text": message,
		"color": Color.YELLOW,
		"duration": 2.0
	})
