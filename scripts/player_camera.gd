extends Node3D

@export_group("Camera Settings")
@export var sensitivity: float = 0.002
@export var camera_limit_degrees: float = 85.0
@export var camera_distance: float = 5.0
@export var camera_height: float = 2.0
@export var camera_offset: Vector3 = Vector3(0, 0, 0)

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

# Track rotation in Euler angles
var camera_rotation: Vector3 = Vector3.ZERO

# Signal to inform player_movement about camera changes
signal camera_rotated(camera_basis: Basis)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Configure SpringArm3D
	spring_arm.spring_length = camera_distance
	spring_arm.position.y = camera_height
	spring_arm.position += camera_offset
	
	spring_arm.add_excluded_object(get_parent())
	spring_arm.collision_mask = 1
	spring_arm.margin = 0.5

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_rotation.x -= event.relative.y * sensitivity
		camera_rotation.y -= event.relative.x * sensitivity
		
		# Clamp vertical rotation
		camera_rotation.x = clamp(
			camera_rotation.x, 
			deg_to_rad(-camera_limit_degrees), 
			deg_to_rad(camera_limit_degrees)
		)
		
		# Apply rotations using transforms
		transform.basis = Basis()
		transform.basis = transform.basis.rotated(Vector3.UP, camera_rotation.y)
		spring_arm.transform.basis = Basis()
		spring_arm.transform.basis = spring_arm.transform.basis.rotated(Vector3.RIGHT, camera_rotation.x)
		
		# Emit signal with updated camera basis
		emit_signal("camera_rotated", camera.global_transform.basis)
