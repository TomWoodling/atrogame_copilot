# dialog_manager.gd
extends Node

# This manager handles loading, storing, and retrieving dialogs

# Dictionary of loaded dialogs, indexed by ID
var dialogs: Dictionary = {}

func _ready() -> void:
	# Connect to encounter manager signals
#	EncounterManager.dialog_started.connect(_on_dialog_started)
	
	# Load dialogs
	load_dialogs()

func load_dialogs() -> void:
	# Method 1: Load from Resource files
	_load_dialog_resources()
	
	# Method 2: Create dialogs programmatically for testing
	_create_test_dialogs()

func _load_dialog_resources() -> void:
	# Scan for dialog resources in the dialog directory
	var dir = DirAccess.open("res://resources/dialogs")
	if not dir:
		push_error("Failed to open dialog directory")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var dialog = load("res://resources/dialogs/" + file_name)
			if dialog is DialogContainer:
				dialogs[dialog.dialog_id] = dialog
		
		file_name = dir.get_next()

func _create_test_dialogs() -> void:
	# Create a few test dialogs programmatically
	
	# Info dialog example
	var info_dialog = DialogContainer.new()
	info_dialog.dialog_id = "tutorial_intro"
	info_dialog.add_entry("Mission Control", "Welcome to Mars Base Alpha, astronaut.")
	info_dialog.add_entry("Mission Control", "Your primary objective is to establish a functional outpost.")
	info_dialog.add_entry("Mission Control", "Begin by collecting necessary resources in the vicinity.")
	dialogs[info_dialog.dialog_id] = info_dialog
	
	# NPC dialog example
	var npc_dialog = DialogContainer.new()
	npc_dialog.dialog_id = "engineer_first_meeting"
	npc_dialog.add_entry("Engineer", "Hey there! I'm the base engineer.", "positive")
	npc_dialog.add_entry("Engineer", "I need some materials to fix our oxygen system.", "neutral")
	npc_dialog.add_entry("Engineer", "Could you help me find some titanium components?", "neutral")
	npc_dialog.add_entry("You", "Sure, I'll keep an eye out for them.")
	npc_dialog.add_entry("Engineer", "Great! You're a lifesaver!", "positive", "DANCE")
	dialogs[npc_dialog.dialog_id] = npc_dialog

func get_dialog(dialog_id: String) -> DialogContainer:
	if dialog_id in dialogs:
		return dialogs[dialog_id]
	
	push_warning("Dialog ID not found: " + dialog_id)
	return null

func _on_dialog_started(dialog: DialogContainer) -> void:
	# You could do additional processing here if needed
	pass

# Create a new dialog and add it to the manager
func create_dialog(dialog_id: String) -> DialogContainer:
	var dialog = DialogContainer.new()
	dialog.dialog_id = dialog_id
	dialogs[dialog_id] = dialog
	return dialog
