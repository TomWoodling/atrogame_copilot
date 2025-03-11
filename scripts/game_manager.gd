extends Node

signal game_state_changed(new_state: GameState)

enum GameState { INITIALIZING, PLAYING, PAUSED }
var current_state: GameState = GameState.INITIALIZING
var is_initialized: bool = false
var player : Node3D

func _ready() -> void:
	# Connect to ProcessManager signals to sync states
	ProcessManager.process_state_changed.connect(_on_process_state_changed)

func initialize() -> void:
	if is_initialized:
		return
		
	current_state = GameState.PLAYING
	is_initialized = true
	
func can_player_move() -> bool:
	# Now checks both GameManager state and ProcessManager state
	return current_state == GameState.PLAYING and not ProcessManager.is_gameplay_blocked()
	
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		# Let ProcessManager handle the actual pause state
		current_state = GameState.PAUSED
		
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		# Let ProcessManager handle returning to normal state
		current_state = GameState.PLAYING

func _on_process_state_changed(old_state: ProcessManager.ProcessState, new_state: ProcessManager.ProcessState) -> void:
	match new_state:
		ProcessManager.ProcessState.PAUSED:
			if current_state != GameState.PAUSED:
				current_state = GameState.PAUSED
				game_state_changed.emit(GameState.PAUSED)
				
		ProcessManager.ProcessState.NORMAL:
			if current_state == GameState.PAUSED:
				current_state = GameState.PLAYING
				game_state_changed.emit(GameState.PLAYING)
