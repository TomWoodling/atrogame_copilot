extends Node

# Define different process states the game can be in
enum ProcessState {
	NORMAL,      # Regular gameplay
	PAUSED,      # Game is paused
	CUTSCENE,    # Playing a cutscene
	TRANSITION,  # Scene/level transition
	DIALOG       # Dialog or important message display
}

# Current process state
var current_state: ProcessState = ProcessState.NORMAL

# Signal to notify when process state changes
signal process_state_changed(old_state: ProcessState, new_state: ProcessState)

func _ready() -> void:
	# Ensure this node always processes
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	match current_state:
				
		ProcessState.CUTSCENE:
			if event.is_action_pressed("ui_cancel"):
				# Future: Implement cutscene skip confirmation
				pass
		
		ProcessState.DIALOG:
			if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
				# Future: Handle dialog advancement
				pass

# Change the process state and emit signal for other systems to react
func set_process_state(new_state: ProcessState) -> void:
	var old_state = current_state
	current_state = new_state
	
	# Emit signal for other systems to react to state change
	process_state_changed.emit(old_state, new_state)

# Pause handling
func enter_paused() -> void:
	set_process_state(ProcessState.PAUSED)
	
func exit_paused() -> void:
	set_process_state(ProcessState.NORMAL)


# Utility functions for common state changes
func enter_cutscene() -> void:
	set_process_state(ProcessState.CUTSCENE)
	# Future: Additional cutscene setup

func exit_cutscene() -> void:
	set_process_state(ProcessState.NORMAL)
	# Future: Additional cutscene cleanup

func show_dialog() -> void:
	set_process_state(ProcessState.DIALOG)
	# Future: Dialog system integration

func enter_transition() -> void:
	set_process_state(ProcessState.TRANSITION)
	# Future: Scene transition handling

# Check if we're in a state that should block normal gameplay
func is_gameplay_blocked() -> bool:
	return current_state != ProcessState.NORMAL
