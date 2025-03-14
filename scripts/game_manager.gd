extends Node

signal game_state_changed(new_state: GameState)
signal inventory_state_changed(is_open: bool)

enum GameState { INITIALIZING, PLAYING, PAUSED }
enum GameplayState { NORMAL, INVENTORY }

var current_state: GameState = GameState.INITIALIZING
var gameplay_state: GameplayState = GameplayState.NORMAL
var is_initialized: bool = false
var player : Node3D

func _ready() -> void:
	ProcessManager.process_state_changed.connect(_on_process_state_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# ESC always returns to normal playing state
		if current_state == GameState.PAUSED or gameplay_state == GameplayState.INVENTORY:
			return_to_normal_state()
	elif event.is_action_pressed("pause"):
		# Dedicated pause button toggles pause state
		if current_state == GameState.PLAYING:
			pause_game()
		elif current_state == GameState.PAUSED:
			resume_game()
	elif event.is_action_pressed("inventory"):
		# Inventory toggle only works during PLAYING state
		if current_state == GameState.PLAYING:
			toggle_inventory()

func return_to_normal_state() -> void:
	# Return to normal playing state regardless of current state
	if current_state == GameState.PAUSED:
		resume_game()
	if gameplay_state == GameplayState.INVENTORY:
		_set_gameplay_state(GameplayState.NORMAL)

func toggle_inventory() -> void:
	if current_state != GameState.PLAYING:
		return
		
	var new_state = GameplayState.NORMAL if gameplay_state == GameplayState.INVENTORY else GameplayState.INVENTORY
	_set_gameplay_state(new_state)

func _set_gameplay_state(new_state: GameplayState) -> void:
	if gameplay_state == new_state:
		return

	gameplay_state = new_state
	
	match gameplay_state:
		GameplayState.NORMAL:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			inventory_state_changed.emit(false)
		GameplayState.INVENTORY:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			inventory_state_changed.emit(true)

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		game_state_changed.emit(current_state)

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		# Restore mouse mode based on gameplay state
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if gameplay_state == GameplayState.NORMAL else Input.MOUSE_MODE_VISIBLE
		game_state_changed.emit(current_state)

func initialize() -> void:
	if is_initialized:
		return
		
	current_state = GameState.PLAYING
	gameplay_state = GameplayState.NORMAL
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_initialized = true
	
func can_player_move() -> bool:
	return current_state == GameState.PLAYING and gameplay_state == GameplayState.NORMAL

func _on_process_state_changed(old_state: int, new_state: int) -> void:
	# Handle any necessary state synchronization with ProcessManager
	pass
