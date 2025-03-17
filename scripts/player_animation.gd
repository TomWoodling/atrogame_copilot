extends AnimationTree

# Node references
@onready var parent: CharacterBody3D = get_parent().get_parent()
@onready var animation_state_machine: AnimationNodeStateMachinePlayback = get("parameters/playback")

# Animation parameters
@export_group("Animation Thresholds")
@export var falling_threshold: float = -8.0  # Negative value for downward velocity
@export var splat_anim_duration: float = 1.0  # Estimated duration of splat animation
@export var stand_anim_duration: float = 1.2  # Estimated duration of stand animation

# Animation states
enum AnimState {
	IDLE,
	WALK,
	RUN,
	JUMP,
	FALLING,
	SPLAT,
	STAND,
	SUCCESS
}

# State tracking
var current_state: AnimState = AnimState.IDLE
var was_on_floor: bool = true
var previous_gameplay_state: int = -1
var animation_locked: bool = false

func _ready() -> void:
	# Set the active state initially to Idle
	animation_state_machine.travel("Idle")
	
	# Connect to necessary signals
	GameManager.scan_completed.connect(_on_scan_completed)
	
	# Store initial gameplay state
	previous_gameplay_state = GameManager.gameplay_state
	
	# Connect to animation finished signal
	#if animation_state_machine.has_method("connect"):
		#animation_state_machine.connect("animation_finished", _on_animation_finished)

func _physics_process(delta: float) -> void:
	if animation_locked:
		# Don't process state changes if locked in an animation sequence
		return

	# Don't process if we're in a special state (SPLAT or STAND)
	if current_state == AnimState.SPLAT or current_state == AnimState.STAND:
		return
		
	# Check if the gameplay state has changed
	if GameManager.gameplay_state != previous_gameplay_state:
		previous_gameplay_state = GameManager.gameplay_state
		if GameManager.gameplay_state == GameManager.GameplayState.CUTSCENE:
			_play_success_animation()
			return
	
	# If we're in STUNNED state, don't process further
	if GameManager.gameplay_state == GameManager.GameplayState.STUNNED:
		return
	
	# Get current state information
	var on_floor = parent.is_on_floor()
	var velocity = parent.velocity
	var speed = Vector2(velocity.x, velocity.z).length()
	var is_running = Input.is_action_pressed("run") && GameManager.gameplay_state == GameManager.GameplayState.NORMAL
	
	# Determine appropriate animation state
	var target_state = _determine_animation_state(on_floor, speed, velocity.y, is_running)
	
	# Apply the animation if different from current
	if target_state != current_state:
		_apply_animation_state(target_state)
	
	# Update tracking variables
	was_on_floor = on_floor

func _determine_animation_state(on_floor: bool, speed: float, y_velocity: float, is_running: bool) -> int:
	# Handle jumping - parent.is_jumping is checked from player_movement.gd
	if parent.is_jumping:
		return AnimState.JUMP
	
	# Handle movement on the ground
	if on_floor:
		if speed > 0.1:  # Small threshold to account for floating-point errors
			if is_running:
				return AnimState.RUN
			else:
				return AnimState.WALK
		else:
			return AnimState.IDLE
	
	# If not on floor and not jumping, use Jump animation for small drops
	# Note: FALLING state is now handled by the fall_detector
	return AnimState.JUMP
	
	# Default to current state if no conditions are met
	return current_state

func _apply_animation_state(new_state: int) -> void:
	# Only update if there's a change and we're not in a locked sequence
	if new_state == current_state or animation_locked:
		return
		
	current_state = new_state
	
	match current_state:
		AnimState.IDLE:
			animation_state_machine.travel("Idle")
		AnimState.WALK:
			animation_state_machine.travel("Walk")
		AnimState.RUN:
			animation_state_machine.travel("Run")
		AnimState.JUMP:
			animation_state_machine.travel("Jump")
		AnimState.FALLING:
			animation_state_machine.travel("Falling")
		AnimState.SPLAT:
			animation_state_machine.travel("Splat")
			_trigger_stun()
		AnimState.STAND:
			animation_state_machine.travel("Stand")
		AnimState.SUCCESS:
			animation_state_machine.travel("Success")

func _trigger_stun() -> void:
	# Inform the GameManager of the stunned state
	var previous_state = GameManager.gameplay_state
	GameManager.enter_stunned()
	previous_gameplay_state = previous_state

func _on_scan_completed() -> void:
	_play_success_animation()

func _play_success_animation() -> void:
	# Only play success if not already in a special animation
	if current_state != AnimState.SPLAT and current_state != AnimState.STAND and current_state != AnimState.SUCCESS:
		_apply_animation_state(AnimState.SUCCESS)
		animation_locked = true
		
		# Timer to return to normal state after animation
		await get_tree().create_timer(2.0).timeout
		animation_locked = false
		
		# Return to appropriate animation based on current conditions
		var on_floor = parent.is_on_floor()
		var speed = Vector2(parent.velocity.x, parent.velocity.z).length()
		var is_running = Input.is_action_pressed("run")
		_apply_animation_state(_determine_animation_state(on_floor, speed, parent.velocity.y, is_running))

func _on_animation_finished(anim_name: String) -> void:
	# Handle animation sequence completions
	match anim_name:
		"Splat":
			print("splat")
			# Automatically transition to Stand animation
			_apply_animation_state(AnimState.STAND)
		"Stand":
			# Exit stunned state when Stand animation completes
			animation_locked = false
			GameManager.exit_stunned()
			# Return to idle state
			_apply_animation_state(AnimState.IDLE)
