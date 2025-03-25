extends Node

# Game state management signals
signal game_state_changed(new_state: GameState)
signal inventory_state_changed(is_open: bool)
signal gameplay_state_changed(new_state: GameplayState)

# Scanning-specific signals for tracking scanning processes
signal scan_started
signal scan_completed
signal scan_interrupted

# Enums for clear, type-safe state management
enum GameState { 
	INITIALIZING,  # Game is starting up
	PLAYING,       # Active gameplay
	PAUSED         # Game is paused
}

enum GameplayState { 
	NORMAL,        # Standard gameplay
	INVENTORY,     # Inventory screen open
	SCANNING,      # Player is performing a scan
	ENCOUNTER,     # Interacting with an NPC or challenge
	CUTSCENE,      # Cinematic moment (placeholder for future implementation)
	STUNNED        # Player cannot move (e.g., after falling or hit by hazard)
}

# Core state tracking variables
var current_state: GameState = GameState.INITIALIZING
var gameplay_state: GameplayState = GameplayState.NORMAL
var is_initialized: bool = false

# Reference to the player object
var player : Node3D

func _ready() -> void:
	# Connect to process and encounter manager signals for state synchronization
	ProcessManager.process_state_changed.connect(_on_process_state_changed)
	EncounterManager.encounter_started.connect(_on_encounter_started)
	EncounterManager.encounter_completed.connect(_on_encounter_completed)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	# Only handle input during active gameplay
	if event.is_action_pressed("ui_cancel"):
		print("pressed esc")
		handle_ui_cancel()
	

func toggle_pause() -> void:
	# Simplified pause toggling, only works during active gameplay
	if current_state == GameState.PLAYING:
		pause_game()
	elif current_state == GameState.PAUSED:
		resume_game()

func handle_ui_cancel() -> void:
	print("gm cancel")
	# Comprehensive ui_cancel handling with clear state management
	match current_state:
		GameState.PLAYING:
			match gameplay_state:
				GameplayState.NORMAL:
					print("gm pause")
					# In normal state, pause game
					toggle_pause()
				
				GameplayState.INVENTORY:
					# From inventory, return to normal state
					return_to_normal_state()
				[
				GameplayState.SCANNING, 
				GameplayState.ENCOUNTER, 
				GameplayState.STUNNED
				]:
					# For these states, do nothing
					pass
		GameState.PAUSED:
			print("gm resume")
			toggle_pause()

func return_to_normal_state() -> void:
	# Robust method to reset to normal playing state
	if current_state == GameState.PAUSED:
		resume_game()
	
	# Force set gameplay state to NORMAL, regardless of current state
	_set_gameplay_state(GameplayState.NORMAL)

func toggle_inventory() -> void:
	# Simplified inventory toggle 
	# Only works during active gameplay
	if current_state != GameState.PLAYING:
		return
	
	# Toggle between NORMAL and INVENTORY states
	var new_state = GameplayState.NORMAL if gameplay_state == GameplayState.INVENTORY else GameplayState.INVENTORY
	_set_gameplay_state(new_state)

func _set_gameplay_state(new_state: GameplayState) -> void:
	# Prevents redundant state changes
	if gameplay_state == new_state:
		return

	var old_state = gameplay_state
	gameplay_state = new_state
	
	# Manage mouse cursor based on gameplay state
	match new_state:
		GameplayState.NORMAL:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			inventory_state_changed.emit(false)
		GameplayState.INVENTORY:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			inventory_state_changed.emit(true)
		[
		GameplayState.SCANNING, 
		GameplayState.ENCOUNTER, 
		GameplayState.STUNNED
		]:
			# Keep mouse captured during special states
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Notify other systems of gameplay state change
	gameplay_state_changed.emit(gameplay_state)

func pause_game() -> void:
	# Ensure we can only pause during active gameplay
	if current_state != GameState.PLAYING or gameplay_state == GameplayState.CUTSCENE:
		return
	
	current_state = GameState.PAUSED
	ProcessManager.enter_paused()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Stop physics and pause the entire game tree
	get_tree().paused = true
	
	game_state_changed.emit(current_state)

func resume_game() -> void:
	print("resume")
	# Can only resume if currently paused
	if current_state != GameState.PAUSED:
		return
	ProcessManager.exit_paused()
	current_state = GameState.PLAYING
	print("gm state: ",current_state)
	get_tree().paused = false
	
	# Restore mouse mode based on current gameplay state
	match gameplay_state:
		[GameplayState.NORMAL, GameplayState.SCANNING, 
		 GameplayState.ENCOUNTER, GameplayState.STUNNED]:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GameplayState.INVENTORY:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	game_state_changed.emit(current_state)

func initialize() -> void:
	# Initialization method to set up initial game state
	if is_initialized:
		return
	
	current_state = GameState.PLAYING
	gameplay_state = GameplayState.NORMAL
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_initialized = true

func can_player_move() -> bool:
	# Determine if player movement is allowed based on current state
	return current_state == GameState.PLAYING and (
		gameplay_state == GameplayState.NORMAL or 
		(gameplay_state == GameplayState.ENCOUNTER and EncounterManager.active_challenge != EncounterManager.ChallengeType.NONE)
	)

func _on_process_state_changed(old_state: int, new_state: int) -> void:
	print("changing from: ",old_state," changing to: ",new_state)
	# Placeholder for process state synchronization logic
	pass

func start_scanning() -> void:
	# Enter scanning state if possible
	if current_state == GameState.PLAYING and gameplay_state == GameplayState.NORMAL:
		_set_gameplay_state(GameplayState.SCANNING)
		scan_started.emit()

func stop_scanning() -> void:
	# Exit scanning state
	if gameplay_state == GameplayState.SCANNING:
		_set_gameplay_state(GameplayState.NORMAL)

func enter_stunned() -> void:
	# Enter stunned state
	_set_gameplay_state(GameplayState.STUNNED)

func exit_stunned() -> void:
	# Exit stunned state
	_set_gameplay_state(GameplayState.NORMAL)

# Encounter management methods
func _on_encounter_started(npc: NPController) -> void:
	# Placeholder for encounter start logic
	pass
	
func _on_encounter_completed(npc: NPController) -> void:
	# Placeholder for encounter completion logic
	pass
