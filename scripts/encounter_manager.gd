extends Node

signal state_changed(old_type: EncounterType, new_type: EncounterType)
signal encounter_started(type: EncounterType)
signal encounter_completed(type: EncounterType)
signal encounter_failed(type: EncounterType)

enum EncounterType {
	INFO,
	COLLECTION,
	NPC,
	CHALLENGE
}

# Current encounter state
var current_encounter: EncounterType = EncounterType.INFO
var is_encounter_active: bool = false

# Encounter type names for string conversion
const ENCOUNTER_NAMES = {
	EncounterType.INFO: "info",
	EncounterType.COLLECTION: "collection",
	EncounterType.NPC: "npc",
	EncounterType.CHALLENGE: "challenge"
}

# Configuration for different encounter types
const ENCOUNTER_CONFIGS = {
	EncounterType.INFO: {
		"message": "Info: %s",  # Format string for custom messages
		"default_message": "This is the default message for debug",
		"color": Color(0.9, 0.9, 0.2),  # Yellow
		"duration": 3.0,
		"can_fail": false
	},
	EncounterType.COLLECTION: {
		"message": "Collection Task: Gather the resources",
		"color": Color(0.2, 0.8, 0.2),  # Green
		"duration": 3.0,
		"can_fail": true
	},
	EncounterType.NPC: {
		"message": "NPC Encounter: Someone needs help",
		"color": Color(0.2, 0.2, 0.8),  # Blue
		"duration": 3.0,
		"can_fail": true
	},
	EncounterType.CHALLENGE: {
		"message": "Challenge: Test your skills",
		"color": Color(0.8, 0.2, 0.2),  # Red
		"duration": 3.0,
		"can_fail": true
	}
}

func _ready() -> void:
	# Verify our enum assumptions
	assert(EncounterType.INFO == 0, "INFO must be the first enum value for safe default")
	# Connect to ProcessManager to handle process state changes
	ProcessManager.process_state_changed.connect(_on_process_state_changed)

func _on_process_state_changed(old_state: ProcessManager.ProcessState, new_state: ProcessManager.ProcessState) -> void:
	# If we enter a blocking state, auto-complete any active INFO encounters
	if new_state != ProcessManager.ProcessState.NORMAL and is_encounter_active and current_encounter == EncounterType.INFO:
		complete_encounter()

func get_type_from_string(txt_string: String) -> EncounterType:
	# Default to INFO if string is empty or invalid
	if txt_string.is_empty():
		push_warning("Empty encounter type provided, defaulting to INFO")
		return EncounterType.INFO
		
	for type in EncounterType.values():
		if ENCOUNTER_NAMES[type] == txt_string.to_lower():
			return type
			
	push_warning("Invalid encounter type string: %s, defaulting to INFO" % txt_string)
	return EncounterType.INFO

func change_state(new_type: EncounterType) -> void:
	var old_type = current_encounter
	if old_type != new_type:
		current_encounter = new_type
		emit_signal("state_changed", old_type, new_type)

func start_encounter(type: EncounterType, custom_message: String = "") -> void:
	if is_encounter_active:
		push_warning("Attempting to start encounter while another is active")
		return
		
	if not ENCOUNTER_CONFIGS.has(type):
		push_warning("Invalid encounter type: %d, defaulting to INFO" % type)
		type = EncounterType.INFO
		custom_message = ENCOUNTER_CONFIGS[EncounterType.INFO].default_message
		
	var config = ENCOUNTER_CONFIGS[type]
	var message = config.message
	
	# For INFO types, format with custom message or use default
	if type == EncounterType.INFO:
		message = message % (custom_message if not custom_message.is_empty() 
						   else config.default_message)
	
	HUDManager.show_message({
		"text": message,
		"color": config.color,
		"duration": config.duration
	})
	
	is_encounter_active = true
	change_state(type)
	emit_signal("encounter_started", type)

func complete_encounter(type: EncounterType = current_encounter) -> void:
	if not is_encounter_active:
		return
		
	if not ENCOUNTER_CONFIGS.has(type):
		type = EncounterType.INFO
		
	HUDManager.show_message({
		"text": "Encounter completed!",
		"color": Color.GREEN,
		"duration": 2.0
	})
	
	is_encounter_active = false
	change_state(EncounterType.INFO)  # Return to safe state
	emit_signal("encounter_completed", type)

func fail_encounter(type: EncounterType = current_encounter) -> void:
	if not is_encounter_active:
		return
		
	if not ENCOUNTER_CONFIGS.has(type) or not ENCOUNTER_CONFIGS[type].can_fail:
		return
		
	HUDManager.show_message({
		"text": "Encounter failed!",
		"color": Color.RED,
		"duration": 2.0
	})
	
	is_encounter_active = false
	change_state(EncounterType.INFO)  # Return to safe state
	emit_signal("encounter_failed", type)
