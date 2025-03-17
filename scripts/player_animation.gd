extends AnimationTree

# Node references
@onready var parent: CharacterBody3D = get_parent().get_parent()
@onready var animation_state_machine: AnimationNodeStateMachinePlayback = get("parameters/playback")

# Animation parameters
@export_group("Animation Thresholds")
@export var falling_threshold: float = -8.0  # Negative value for downward velocity
@export var fall_distance_threshold: float = 3.0  # Units of height to detect a fall
@export var stunned_recovery_time: float = 1.2  # Time to recover from stun
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
var fall_start_position: float = 0.0
var is_stunned: bool = false
var stun_timer: float = 0.0
var previous_gameplay_state: int = -1
var animation_sequence_active: bool = false
var animation_locked: bool = false

func _ready() -> void:
	# Set the active state initially to Idle
	animation_state_machine.travel("Idle")
	
	# Connect to necessary signals
	GameManager.scan_completed.connect(_on_scan_completed)
	
	# Store initial gameplay state
	previous_gameplay_state = GameManager.gameplay_state
	
	# Connect to animation finished signal
	#animation_state_machine.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if animation_locked:
		# Don't process state changes if locked in an animation sequence
		return
		
	if is_stunned:
		_handle_stunned_state(delta)
		return
		
	# Check if the gameplay state has changed
	if GameManager.gameplay_state != previous_gameplay_state:
		previous_gameplay_state = GameManager.gameplay_state
		if GameManager.gameplay_state == GameManager.GameplayState.CUTSCENE:
			_play_success_animation()
			return
	
	# Get current state information
	var on_floor = parent.is_on_floor()
	var velocity = parent.velocity
	var speed = Vector2(velocity.x, velocity.z).length()
	var is_running = Input.is_action_pressed("run") && GameManager.gameplay_state == GameManager.GameplayState.NORMAL
	
	# Track falling
	if was_on_floor && !on_floor:
		fall_start_position = parent.global_position.y
	
	# Calculate fall distance
	var fall_distance = fall_start_position - parent.global_position.y if !on_floor else 0.0
	
	# Determine appropriate animation state
	var target_state = _determine_animation_state(on_floor, speed, velocity.y, is_running, fall_distance)
	
	# Apply the animation if different from current
	if target_state != current_state:
		_apply_animation_state(target_state)
	
	# Update tracking variables
	was_on_floor = on_floor

func _determine_animation_state(on_floor: bool, speed: float, y_velocity: float, is_running: bool, fall_distance: float) -> int:
	# Don't change animation during sequence
	if animation_sequence_active:
		return current_state
		
	# Handle jumping - parent.is_jumping is checked from player_movement.gd
	if parent.is_jumping:
		return AnimState.JUMP
	
	# Handle falling
	if !on_floor:
		if y_velocity < falling_threshold && fall_distance > fall_distance_threshold:
			return AnimState.FALLING
		elif y_velocity < 0:
			return AnimState.JUMP  # Use jump animation for small drops
	
	# Handle movement on the ground
	if on_floor:
		if speed > 0.1:  # Small threshold to account for floating-point errors
			if is_running:
				return AnimState.RUN
			else:
				return AnimState.WALK
		else:
			return AnimState.IDLE
	
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
	is_stunned = true
	stun_timer = 0.0
	animation_sequence_active = true
	# Inform the GameManager of the stunned state
	var previous_state = GameManager.gameplay_state
	GameManager.enter_stunned()
	previous_gameplay_state = previous_state

func _handle_stunned_state(delta: float) -> void:
	# Most of the logic is now handled by animation signals
	# This function is kept minimal
	stun_timer += delta
	
	# Only if we need to manually transition from Splat to Stand
	# (This can be removed if using auto-advance transitions)
	if stun_timer >= stunned_recovery_time * 0.5 && current_state == AnimState.SPLAT:
		_apply_animation_state(AnimState.STAND)

func _on_scan_completed() -> void:
	_play_success_animation()

func _play_success_animation() -> void:
	# Only play success if not already in a special animation
	if !is_stunned && !animation_sequence_active && current_state != AnimState.SUCCESS:
		_apply_animation_state(AnimState.SUCCESS)
		animation_locked = true
		
		# Timer to return to normal state after animation
		await get_tree().create_timer(2.0).timeout
		animation_locked = false
		
		# Return to appropriate animation based on current conditions
		var on_floor = parent.is_on_floor()
		var speed = Vector2(parent.velocity.x, parent.velocity.z).length()
		var is_running = Input.is_action_pressed("run")
		_apply_animation_state(_determine_animation_state(on_floor, speed, parent.velocity.y, is_running, 0))

# Called when landing with significant velocity
func handle_hard_landing(landing_velocity: float) -> void:
	if landing_velocity < falling_threshold * 1.5 && !animation_sequence_active:
		# Start the full sequence Falling > Splat > Stand
		animation_sequence_active = true
		animation_locked = true
		_trigger_stun()
		
		# Make sure we're in falling animation first if not already
		if current_state != AnimState.FALLING:
			_apply_animation_state(AnimState.FALLING)
			# Wait a short time before transitioning to splat
			get_tree().create_timer(0.1).timeout.connect(func():
				_apply_animation_state(AnimState.SPLAT)
			)
		else:
			# If already falling, go directly to splat
			_apply_animation_state(AnimState.SPLAT)

# Optional: Add this if your AnimationTree can emit signals
func _on_animation_finished(anim_name: String) -> void:
	# Handle animation sequence completions
	match anim_name:
		"Splat":
			# Automatically transition to Stand animation
			# This is redundant if using auto-advance, but included for clarity
			_apply_animation_state(AnimState.STAND)
		"Stand":
			# Exit stunned state when Stand animation completes
			animation_sequence_active = false
			animation_locked = false
			is_stunned = false
			GameManager.exit_stunned()
			# Return to idle state
			_apply_animation_state(AnimState.IDLE)
