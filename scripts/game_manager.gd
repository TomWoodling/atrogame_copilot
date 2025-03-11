extends Node

signal game_state_changed(new_state: String)

enum GameState { INITIALIZING, PLAYING, PAUSED }
var current_state: GameState = GameState.INITIALIZING
var is_initialized: bool = false
var player : Node3D

func initialize() -> void:
	if is_initialized:
		return
		
	current_state = GameState.PLAYING
	is_initialized = true
	
func can_player_move() -> bool:
	return current_state == GameState.PLAYING
	
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		emit_signal("game_state_changed", "paused")
		
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		emit_signal("game_state_changed", "playing")
		print("resume")
