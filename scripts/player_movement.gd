# Modified player_movement.gd to handle movement physics
extends CharacterBody3D

@export_group("Astronaut Movement")
@export var walk_speed: float = 4.0
@export var run_multiplier: float = 1.75
@export var acceleration: float = 5.0
@export var friction: float = 2.0
@export var rotation_speed: float = 4.0
@export var rotation_acceleration: float = 8.0
@export var rotation_deceleration: float = 4.0

@export_group("Lunar Jump Parameters")
@export var jump_strength: float = 12.0
@export var jump_horizontal_force: float = 4.0
@export var air_damping: float = 0.25
@export var gravity: float = 5.0
@export var max_fall_speed: float = 15.0
@export var air_control: float = 0.6
@export var air_brake: float = 0.15
@export var landing_cushion: float = 2.0

@export_group("State Modifiers")
@export var scanning_speed_mult: float = 0.5
@export var scanning_rotation_mult: float = 0.5
@export var interaction_speed_mult: float = 0.3
@export var interaction_rotation_mult: float = 0.3
@export var stunned_speed_mult: float = 0.0       # No movement during stun
@export var stunned_rotation_mult: float = 0.0    # No rotation during stun
@export var stunned_recovery_speed_mult: float = 0.3  # Slow movement during recovery
@export var original_air_control: float = 1.0

const JUMP_DURATION: float = 0.6

# Node references
@onready var camera_rig: Node3D = $CameraRig
@onready var mesh: Node3D = $meshy_snaut
@onready var animation_tree = null
@onready var fall_detector: FallDetector = $FallDetector

# Movement state
var move_direction: Vector3 = Vector3.ZERO
var camera_basis: Basis = Basis.IDENTITY
var target_basis: Basis = Basis.IDENTITY
var current_rotation_speed: float = 0.0
var was_in_air: bool = false
var current_speed: float = 0.0

# Jump state
var jump_time: float = 0.0
var is_jumping: bool = false
var can_jump: bool = true
var is_falling: bool = false

func _ready() -> void:
	assert(camera_rig != null, "Camera rig node not found!")
	assert(mesh != null, "Mesh node not found!")
	assert(fall_detector != null, "Fall detector node not found!")
	
	# Store original air control value
	original_air_control = air_control
	
	# Get reference to the animation tree
	animation_tree = mesh.get_node("AnimationTree")
	assert(animation_tree != null, "Animation tree not found!")
	
	# Connect to camera signals
	if camera_rig.has_signal("camera_rotated"):
		camera_rig.connect("camera_rotated", _on_camera_rotated)
	
	# Connect to fall detector signals
	fall_detector.falling_state_changed.connect(_on_falling_state_changed)
	fall_detector.player_landed.connect(_on_player_landed)  # Update to new signal name

func _on_camera_rotated(new_basis: Basis) -> void:
	camera_basis = new_basis

func _on_falling_state_changed(falling: bool) -> void:
	is_falling = falling
	
	# Adjust air control based on falling state
	if falling:
		# Reduce air control during free-fall to make it feel more weighty
		var falling_air_control_factor = 0.7
		air_control = original_air_control * falling_air_control_factor
	else:
		# Reset air control when not falling
		air_control = original_air_control

func _on_player_landed() -> void:
	# Apply landing effect to velocity if needed
	# This function now just handles physics response to landing
	# The animation will be handled by player_animation.gd
	pass

func _physics_process(delta: float) -> void:
	if not GameManager.can_player_move() && GameManager.gameplay_state != GameManager.GameplayState.STUNNED:
		return
		
	var on_floor = is_on_floor()
	
	# Handle landing and jump reset
	if was_in_air and on_floor:
		_handle_landing()
		can_jump = true
		is_jumping = false
		jump_time = 0.0
	was_in_air = !on_floor
	
	# Apply movement modifiers based on gameplay state
	var speed_modifier = _get_speed_modifier()
	var rotation_modifier = _get_rotation_modifier()
	
	# Jump and gravity handling
	if Input.is_action_just_pressed("jump") and can_jump and on_floor and speed_modifier > 0:
		_initiate_jump()
	
	_update_jump_state(delta)
	_handle_movement(delta, on_floor, speed_modifier, rotation_modifier)
	move_and_slide()

func _initiate_jump() -> void:
	is_jumping = true
	can_jump = false
	jump_time = 0.0
	velocity.y = jump_strength * 0.5  # Initial boost
	_apply_jump_horizontal_momentum()

func _update_jump_state(delta: float) -> void:
	if is_jumping:
		jump_time += delta
		if jump_time >= JUMP_DURATION:
			is_jumping = false
		else:
			var jump_curve = 1.0 - ease(jump_time / JUMP_DURATION, -1.8)
			velocity.y = jump_strength * jump_curve * 2.0
	elif !is_on_floor():
		velocity.y = move_toward(velocity.y, -max_fall_speed, gravity * delta)

func _handle_movement(delta: float, on_floor: bool, speed_mod: float, rot_mod: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_running = Input.is_action_pressed("run") && GameManager.gameplay_state == GameManager.GameplayState.NORMAL
	
	# Movement direction calculation
	move_direction = Vector3.ZERO
	if input_dir != Vector2.ZERO:
		move_direction = _calculate_move_direction(input_dir)
		_handle_rotation(delta, on_floor, rot_mod)
	else:
		current_rotation_speed = move_toward(
			current_rotation_speed,
			0.0,
			rotation_deceleration * delta
		)
	
	# Apply rotation to mesh
	if current_rotation_speed > 0.0:
		var interpolation_factor = current_rotation_speed * delta
		mesh.transform.basis = mesh.transform.basis.slerp(
			target_basis,
			interpolation_factor
		).orthonormalized()
	
	# Calculate and apply velocity
	var base_speed = walk_speed * (run_multiplier if is_running else 1.0)
	var target_speed = base_speed * speed_mod
	current_speed = move_toward(current_speed, target_speed, acceleration * delta)
	var target_velocity = move_direction * current_speed
	
	_apply_movement(target_velocity, delta, on_floor)

func _get_speed_modifier() -> float:
	match GameManager.gameplay_state:
		GameManager.GameplayState.SCANNING:
			return scanning_speed_mult
		GameManager.GameplayState.STUNNED:
			# Use recovering speed if in stand animation
			if animation_tree && animation_tree.current_state == animation_tree.AnimState.STAND:
				return stunned_recovery_speed_mult
			else:
				return stunned_speed_mult
		_:
			return 1.0

func _get_rotation_modifier() -> float:
	match GameManager.gameplay_state:
		GameManager.GameplayState.SCANNING:
			return scanning_rotation_mult
		GameManager.GameplayState.STUNNED:
			return stunned_rotation_mult
		_:
			return 1.0

func _calculate_move_direction(input_dir: Vector2) -> Vector3:
	var forward = camera_basis.z
	forward.y = 0
	forward = forward.normalized()
	
	var right = camera_basis.x
	right.y = 0
	right = right.normalized()
	
	return (forward * input_dir.y + right * input_dir.x).normalized()

func _handle_rotation(delta: float, on_floor: bool, rot_mod: float) -> void:
	target_basis = Basis.looking_at(move_direction)
	var current_rotation_acceleration = rotation_acceleration * rot_mod
	
	if !on_floor:
		current_rotation_acceleration *= air_control
	
	current_rotation_speed = move_toward(
		current_rotation_speed,
		rotation_speed * rot_mod,
		current_rotation_acceleration * delta
	)

func _apply_movement(target_velocity: Vector3, delta: float, on_floor: bool) -> void:
	if !on_floor:
		var air_target_velocity = target_velocity * air_control
		if move_direction != Vector3.ZERO:
			velocity.x = move_toward(velocity.x, air_target_velocity.x, acceleration * air_control * delta)
			velocity.z = move_toward(velocity.z, air_target_velocity.z, acceleration * air_control * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, acceleration * air_brake * delta)
			velocity.z = move_toward(velocity.z, 0, acceleration * air_brake * delta)
	else:
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

func _apply_jump_horizontal_momentum() -> void:
	if move_direction != Vector3.ZERO:
		var horizontal_jump = move_direction * jump_horizontal_force
		if Input.is_action_pressed("run"):
			horizontal_jump *= run_multiplier
		velocity.x = horizontal_jump.x * (1.0 - air_damping)
		velocity.z = horizontal_jump.z * (1.0 - air_damping)

func _handle_landing() -> void:
	# Just apply landing cushion to soften vertical velocity
	velocity.y = velocity.y / landing_cushion
	
	# Apply a flat reduction to horizontal movement upon landing
	velocity.x *= 0.7
	velocity.z *= 0.7
