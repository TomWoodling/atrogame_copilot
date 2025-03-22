extends CharacterBody3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 6.0
@export var jump_impulse := 12.0
@export var stopping_speed := 0.7

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 10.0
@export var rotation_speed := 14.0

@onready var _camera_pivot: Node3D = %CameraPoint
@onready var _camera: Camera3D = %Camera3D
@onready var _skin := %meshy_snaut
@onready var state_machine = %AnimationTree["parameters/playback"]
@onready var col_shape : CollisionShape3D = %snautShape
@onready var left_dust : CPUParticles3D = %LfootDust
@onready var right_dust : CPUParticles3D = %RfootDust
@onready var left_step : CPUParticles3D = %LfootStep
@onready var right_step : CPUParticles3D = %RfootStep
@onready var next_step = true
@onready var next_foot_right = true
@export var r_hand_item : PackedScene

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
var _gravity := -12.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity
		
		
func _physics_process(delta: float) -> void:
	if StateManager.text_representation == "MOVING":
		if Input.is_action_pressed("walk") and is_on_floor():
			move_speed = 2.9
		else:
			move_speed = 8.0
			
		_camera_pivot.rotation.x -= _camera_input_direction.y * delta
		_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
		_camera_pivot.rotation.y -= _camera_input_direction.x * delta

		_camera_input_direction = Vector2.ZERO
		
		var raw_input := Input.get_vector("left", "right", "up", "down")
		var forward := _camera.global_basis.z
		var right := _camera.global_basis.x
		var move_direction := forward * raw_input.y + right * raw_input.x
		move_direction.y = 0.0
		move_direction = move_direction.normalized()
		
		var y_velocity := velocity.y
		velocity.y = 0.0
		velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
		velocity.y = y_velocity + _gravity * delta
		
		var is_starting_jump := Input.is_action_just_pressed("jump") and is_on_floor()
		if is_starting_jump:
			velocity.y += jump_impulse
		velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
		if is_equal_approx(move_direction.length(), 0.0) and velocity.length() < stopping_speed:
			velocity.x = 0
			velocity.z = 0
		move_and_slide()
		
		if move_direction.length() > 0.2:
			_last_movement_direction = move_direction
		var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
		_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

		if is_starting_jump:
			state_machine.travel("Jump")
			right_step.emitting = false
			left_step.emitting = false
		#elif not is_on_floor() and velocity.y < 0:
		#	state_machine.travel("Falling")
		elif is_on_floor():
			var ground_speed := velocity.length()
			if ground_speed > 0.0:
				footstep_effect()
				if ground_speed < 3:
					state_machine.travel("Walk")
				else:
					state_machine.travel("Run")
			else:
				state_machine.travel("Idle")
	elif StateManager.text_representation == "FINISHING":
		state_machine.travel("Success")
	else:
		state_machine.travel("Idle")

func footstep_effect():
	if StateManager.in_course == false:
		if next_step == true:
			next_step = false
			if next_foot_right == true:
				next_foot_right = false
				right_dust.emitting = true
				right_step.emitting = true
			else:
				next_foot_right = true
				left_dust.emitting = true
				left_step.emitting = true
			
func _on_rfoot_dust_finished():
	next_step = true

func _on_lfoot_dust_finished():
	next_step = true

func _r_hand_attach(add_scene : String):
	r_hand_item = load(add_scene)
	InventoryManager._set_scepter_state(InventoryManager.hold_states.HELD)
	var r_hand_inst = r_hand_item.instantiate()
	var r_hand_hold = %Rhand_hold
	r_hand_hold.add_child(r_hand_inst)

func _r_hand_detach():
	var r_hand_hold = %Rhand_hold
	r_hand_hold.get_child(0).queue_free()
