extends Node

signal game_state_changed(new_state: GameState)
signal inventory_state_changed(is_open: bool)
signal gameplay_state_changed(new_state: GameplayState)  # New signal for gameplay state changes
# Add scanning-specific signals
signal scan_started
signal scan_completed
signal scan_interrupted

enum GameState { INITIALIZING, PLAYING, PAUSED }
enum GameplayState { 
	NORMAL,
	INVENTORY,
	SCANNING,  # New state for scanning
	ENCOUNTER,  # Handoff to EncounterManager
	CUTSCENE,  # For cinematic moments
	STUNNED   # When player cannot move due to e.g. falling too far or hazards
}

var current_state: GameState = GameState.INITIALIZING
var gameplay_state: GameplayState = GameplayState.NORMAL
var is_initialized: bool = false
var player : Node3D

func _ready() -> void:
	ProcessManager.process_state_changed.connect(_on_process_state_changed)
	
	# Connect to relevant EncounterManager signals if needed
	EncounterManager.encounter_started.connect(_on_encounter_started)
	EncounterManager.encounter_completed.connect(_on_encounter_completed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# ESC handling based on current state
		match gameplay_state:
			GameplayState.NORMAL, GameplayState.SCANNING:
				if current_state == GameState.PLAYING:
					pause_game()
				elif current_state == GameState.PAUSED:
					resume_game()
			GameplayState.INVENTORY:
				return_to_normal_state()
			GameplayState.ENCOUNTER:
				# Potentially let EncounterManager handle ESC during encounters
				# Or implement a way to exit/pause encounters
				pass
				
	elif event.is_action_pressed("pause"):
		# Dedicated pause button toggles pause state
		if current_state == GameState.PLAYING:
			pause_game()
		elif current_state == GameState.PAUSED:
			resume_game()
			
	elif event.is_action_pressed("inventory"):
		# Inventory toggle only works during specific states
		if current_state == GameState.PLAYING and gameplay_state == GameplayState.NORMAL:
			toggle_inventory()

func return_to_normal_state() -> void:
	# Return to normal playing state regardless of current state
	if current_state == GameState.PAUSED:
		resume_game()
	if gameplay_state == GameplayState.INVENTORY:
		_set_gameplay_state(GameplayState.NORMAL)

func toggle_inventory() -> void:
	if current_state != GameState.PLAYING or gameplay_state != GameplayState.NORMAL:
		return
		
	var new_state = GameplayState.NORMAL if gameplay_state == GameplayState.INVENTORY else GameplayState.INVENTORY
	_set_gameplay_state(new_state)

func _set_gameplay_state(new_state: GameplayState) -> void:
	if gameplay_state == new_state:
		return

	var old_state = gameplay_state
	gameplay_state = new_state
	
	match gameplay_state:
		GameplayState.NORMAL:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			inventory_state_changed.emit(false)
		GameplayState.INVENTORY:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			inventory_state_changed.emit(true)
		GameplayState.SCANNING:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GameplayState.ENCOUNTER:
			# For now, keep mouse captured during encounters
			# This may change depending on encounter type (dialog vs challenge)
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GameplayState.STUNNED:
			# Keep mouse captured during stunned state
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Emit signal for the state change
	gameplay_state_changed.emit(gameplay_state)

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		game_state_changed.emit(current_state)

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		# Restore mouse mode based on gameplay state
		match gameplay_state:
			GameplayState.NORMAL, GameplayState.SCANNING, GameplayState.ENCOUNTER, GameplayState.STUNNED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			GameplayState.INVENTORY, GameplayState.CUTSCENE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				
		game_state_changed.emit(current_state)

func initialize() -> void:
	if is_initialized:
		return
		
	current_state = GameState.PLAYING
	gameplay_state = GameplayState.NORMAL
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_initialized = true
	
func can_player_move() -> bool:
	# Updated to consider ENCOUNTER state
	return current_state == GameState.PLAYING and (
		gameplay_state == GameplayState.NORMAL or 
		# You may want encounters to limit movement in certain cases,
		# which would require additional logic here or in EncounterManager
		(gameplay_state == GameplayState.ENCOUNTER and EncounterManager.active_challenge != EncounterManager.ChallengeType.NONE)
	)

func _on_process_state_changed(old_state: int, new_state: int) -> void:
	# Handle any necessary state synchronization with ProcessManager
	pass

func start_scanning() -> void:
	if current_state == GameState.PLAYING and gameplay_state == GameplayState.NORMAL:
		_set_gameplay_state(GameplayState.SCANNING)
		scan_started.emit()

func stop_scanning() -> void:
	if gameplay_state == GameplayState.SCANNING:
		_set_gameplay_state(GameplayState.NORMAL)
		
func enter_stunned() -> void:
	_set_gameplay_state(GameplayState.STUNNED)

func exit_stunned() -> void:
	_set_gameplay_state(GameplayState.NORMAL)

# New methods for handling encounters
func _on_encounter_started(npc: NPController) -> void:
	# Additional game-wide logic when encounters start
	pass
	
func _on_encounter_completed(npc: NPController) -> void:
	# Additional game-wide logic when encounters complete
	pass
