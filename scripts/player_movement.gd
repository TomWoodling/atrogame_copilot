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
const JUMP_DURATION: float = 0.6

@export_group("Scanner Parameters")
@export var scan_move_penalty: float = 0.4  # Movement speed multiplier while scanning
@export var scan_stability_threshold: float = 2.0  # Max velocity for stable scanning

enum AstronautState {
	NORMAL,     # Regular movement state
	JUMPING,    # In jump motion
	FALLING,    # Falling without jump control
	SCANNING,   # Performing scan operation
	LANDING,    # Brief recovery after landing
	STUNNED     # Temporarily disabled after hard impact
}

# Node references
@onready var camera_rig: Node3D = $CameraRig
@onready var mesh: Node3D = $meshy_snaut
@onready var scan_ray: RayCast3D = $meshy_snaut/ScanRay

# State management
var current_state: AstronautState = AstronautState.NORMAL
var state_time: float = 0.0
const LANDING_RECOVERY_TIME: float = 0.3
const STUN_DURATION: float = 1.0

# Movement state
var move_direction: Vector3 = Vector3.ZERO
var camera_basis: Basis = Basis.IDENTITY
var target_basis: Basis = Basis.IDENTITY
var current_rotation_speed: float = 0.0
var was_in_air: bool = false
var landing_velocity: float = 0.0
var current_speed: float = 0.0

# Jump state
var jump_time: float = 0.0

func _ready() -> void:
	assert(camera_rig != null, "Camera rig node not found!")
	assert(mesh != null, "Mesh node not found!")
	assert(scan_ray != null, "Scan ray not found!")
	
	scan_ray.target_position = Vector3(0, 0, -ScannerManager.SCAN_RANGE)
	
	if camera_rig.has_signal("camera_rotated"):
		camera_rig.connect("camera_rotated", _on_camera_rotated)
	
	# Connect to scanner signals
	ScannerManager.scan_completed.connect(_on_scan_completed)
	ScannerManager.scan_failed.connect(_on_scan_failed)

func _on_camera_rotated(new_basis: Basis) -> void:
	camera_basis = new_basis

func _physics_process(delta: float) -> void:
	if not GameManager.can_player_move():
		return
		
	state_time += delta
	var on_floor = is_on_floor()
	
	# Handle landing detection - CRITICAL FIX
	if was_in_air and on_floor and (current_state == AstronautState.FALLING or current_state == AstronautState.JUMPING):
		_handle_landing()
	was_in_air = !on_floor
	
	# Update state based on current conditions
	_update_state(on_floor)
	
	# Handle gravity
	if current_state != AstronautState.SCANNING:
		if current_state == AstronautState.JUMPING:
			jump_time += delta
			if jump_time >= JUMP_DURATION:
				current_state = AstronautState.FALLING
			else:
				var jump_curve = 1.0 - ease(jump_time / JUMP_DURATION, -1.8)
				velocity.y = jump_strength * jump_curve * 2.0
		elif !on_floor:
			landing_velocity = velocity.y
			velocity.y = move_toward(velocity.y, -max_fall_speed, gravity * delta)
	
	# Handle movement based on state
	match current_state:
		AstronautState.NORMAL:
			_handle_normal_movement(delta, on_floor)
		AstronautState.SCANNING:
			_handle_scanning_movement(delta)
		AstronautState.LANDING, AstronautState.STUNNED:
			_handle_restricted_movement(delta)
		_:  # JUMPING or FALLING
			_handle_air_movement(delta)
	
	move_and_slide()

func _update_state(on_floor: bool) -> void:
	match current_state:
		AstronautState.NORMAL:
			if !on_floor:
				current_state = AstronautState.FALLING
			elif Input.is_action_just_pressed("scan") and can_start_scan():
				_attempt_scan()
		AstronautState.FALLING:
			# FIX: This state transition was missing
			if on_floor:
				# State will be set to LANDING or STUNNED in _handle_landing
				pass
		AstronautState.SCANNING:
			if !on_floor or velocity.length() > scan_stability_threshold:
				_interrupt_scan()
		AstronautState.LANDING:
			if state_time >= LANDING_RECOVERY_TIME:
				current_state = AstronautState.NORMAL
				state_time = 0.0  # Reset state timer when changing states
		AstronautState.STUNNED:
			if state_time >= STUN_DURATION:
				current_state = AstronautState.NORMAL
				state_time = 0.0  # Reset state timer when changing states

func _handle_normal_movement(delta: float, on_floor: bool) -> void:
	if Input.is_action_just_pressed("jump") and on_floor:
		current_state = AstronautState.JUMPING
		jump_time = 0.0
		velocity.y = jump_strength * 0.5
		_apply_jump_horizontal_momentum()
	else:
		_handle_movement(delta, on_floor)

func _handle_scanning_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	move_direction = Vector3.ZERO
	
	if input_dir != Vector2.ZERO:
		move_direction = _calculate_move_direction(input_dir)
		_handle_rotation(delta, true)
		
		var scan_speed = walk_speed * scan_move_penalty
		current_speed = move_toward(current_speed, scan_speed, acceleration * delta)
		var target_velocity = move_direction * current_speed
		
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)

func _handle_restricted_movement(delta: float) -> void:
	# Limited movement during landing recovery or stun
	var movement_penalty = 0.3 if current_state == AstronautState.LANDING else 0.0
	_handle_movement(delta, true, movement_penalty)

func _handle_air_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir != Vector2.ZERO:
		move_direction = _calculate_move_direction(input_dir)
		_handle_rotation(delta, false)
		
		var air_target_velocity = move_direction * current_speed * air_control
		velocity.x = move_toward(velocity.x, air_target_velocity.x, acceleration * air_control * delta)
		velocity.z = move_toward(velocity.z, air_target_velocity.z, acceleration * air_control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * air_brake * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * air_brake * delta)

func _handle_movement(delta: float, on_floor: bool, movement_penalty: float = 1.0) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_running = Input.is_action_pressed("run")
	
	move_direction = Vector3.ZERO
	if input_dir != Vector2.ZERO:
		move_direction = _calculate_move_direction(input_dir)
		_handle_rotation(delta, on_floor)
		
		var target_speed = walk_speed * (run_multiplier if is_running else 1.0) * movement_penalty
		current_speed = move_toward(current_speed, target_speed, acceleration * delta)
		var target_velocity = move_direction * current_speed
		
		_apply_movement(target_velocity, delta, on_floor)
	else:
		current_rotation_speed = move_toward(current_rotation_speed, 0.0, rotation_deceleration * delta)
		_apply_movement(Vector3.ZERO, delta, on_floor)

func can_start_scan() -> bool:
	return (current_state == AstronautState.NORMAL and 
			is_on_floor() and 
			velocity.length() < scan_stability_threshold)

func _attempt_scan() -> void:
	if scan_ray.is_colliding():
		var target = scan_ray.get_collider()
		if target is ScannableObject:
			current_state = AstronautState.SCANNING
			state_time = 0.0
			ScannerManager.start_scan(target)

func _interrupt_scan() -> void:
	current_state = AstronautState.NORMAL
	state_time = 0.0
	ScannerManager.scan_failed.emit("Movement interrupted scan")

func _handle_landing() -> void:
	var landing_intensity = abs(landing_velocity) / max_fall_speed
	velocity.y = velocity.y / landing_cushion
	
	velocity.x *= (1.0 - landing_intensity * 0.3)
	velocity.z *= (1.0 - landing_intensity * 0.3)
	
	if landing_intensity > 0.8:  # Hard landing
		current_state = AstronautState.STUNNED
	else:
		current_state = AstronautState.LANDING
	state_time = 0.0

func _calculate_move_direction(input_dir: Vector2) -> Vector3:
	var forward = camera_basis.z
	forward.y = 0
	forward = forward.normalized()
	
	var right = camera_basis.x
	right.y = 0
	right = right.normalized()
	
	return (forward * input_dir.y + right * input_dir.x).normalized()

func _handle_rotation(delta: float, on_floor: bool) -> void:
	target_basis = Basis.looking_at(move_direction)
	var current_rotation_acceleration = rotation_acceleration
	if !on_floor:
		current_rotation_acceleration *= air_control
	
	current_rotation_speed = move_toward(
		current_rotation_speed,
		rotation_speed,
		current_rotation_acceleration * delta
	)
	
	if current_rotation_speed > 0.0:
		var interpolation_factor = current_rotation_speed * delta
		var new_basis = mesh.transform.basis.slerp(target_basis, interpolation_factor)
		mesh.transform.basis = new_basis.orthonormalized()

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

func _on_scan_completed(_target: Node3D, _data: Dictionary) -> void:
	if current_state == AstronautState.SCANNING:
		current_state = AstronautState.NORMAL
		state_time = 0.0

func _on_scan_failed(_reason: String) -> void:
	if current_state == AstronautState.SCANNING:
		current_state = AstronautState.NORMAL
		state_time = 0.0
