extends RayCast3D

class_name FallDetector

# Reference to the player character
@onready var parent: CharacterBody3D = get_parent()
@onready var animation_tree = parent.get_node("meshy_snaut/AnimationTree")

# Configuration
@export var fall_detection_distance: float = 12.0  # Distance to check for ground
@export var fall_detection_delay: float = 0.3      # Time to wait after apex before triggering falling
@export var fall_threshold: float = -8.0           # Negative value for downward velocity to trigger splat
@export var shadow_plane: MeshInstance3D      # Reference to the shadow plane

# State tracking
var is_falling: bool = false
var was_ascending: bool = false
var fall_apex_reached: bool = false
var apex_timer: float = 0.0
var last_y_velocity: float = 0.0
var was_on_floor: bool = true

func _ready() -> void:
	shadow_plane = $"../ShadowPlane"
	# Set target distance
	target_position = Vector3(0, -fall_detection_distance, 0)
	
	# Set debug visualization
	debug_shape_thickness = 2.0
	debug_shape_custom_color = Color(1, 0.5, 0, 0.5)  # Orange for fall detector

	# Set initial shadow visibility to false
	shadow_plane.visible = false

func _physics_process(delta: float) -> void:
	# Skip processing if player is stunned
	if GameManager.gameplay_state == GameManager.GameplayState.STUNNED:
		return
	
	var current_y_velocity = parent.velocity.y
	var on_floor = parent.is_on_floor()
	
	# Check for landing after falling
	if is_falling and !was_on_floor and on_floor:
		_handle_landing(last_y_velocity)
	
	# Only check for falling state if player is not on floor
	if !on_floor:
		# Track last y velocity for landing calculation
		last_y_velocity = current_y_velocity
		
		# Check if player has reached apex of jump (was going up, now going down)
		if was_ascending and current_y_velocity < 0:
			fall_apex_reached = true
			apex_timer = 0.0
		
		# If apex reached, start timer
		if fall_apex_reached:
			apex_timer += delta
			
			# If timer exceeds delay and no ground detected below, trigger falling animation
			if apex_timer > fall_detection_delay and !is_colliding():
				_trigger_falling_animation()
		
		# Update tracking state
		was_ascending = current_y_velocity > 0
		# Update the shadow position
		update_shadow_position()
	else:
		# Reset falling state if player is on floor
		is_falling = false
		fall_apex_reached = false
		apex_timer = 0.0
		shadow_plane.visible = false
	# Update floor state tracking
	was_on_floor = on_floor
	


func _trigger_falling_animation() -> void:
	if is_falling or GameManager.gameplay_state == GameManager.GameplayState.STUNNED:
		return
		
	is_falling = true
	
	# Get the AnimState enum value for FALLING
	var falling_state = animation_tree.AnimState.FALLING
	
	# Set the animation directly
	animation_tree._apply_animation_state(falling_state)
	
	# Notify the parent that we're in a falling state
	parent.set_falling(true)
	
	# Debug visualization
	debug_shape_custom_color = Color(1, 0, 0, 0.5)  # Red when falling detected

func _handle_landing(landing_velocity: float) -> void:
	# Only trigger splat if falling velocity is significant
	if landing_velocity < fall_threshold and parent.is_on_floor() == true:
		# Instead of directly triggering the animation, notify the parent
		parent.trigger_splat()
		
		# Reset falling state
		is_falling = false
		
		# Debug visualization
		debug_shape_custom_color = Color(1, 0.5, 0, 0.5)  # Back to orange

func update_shadow_position():
	# Update the raycast to check for collisions
	force_raycast_update()
	
	if is_colliding():
		# If there is a collision, get the collision point and move the shadow plane there
		var collision_point = get_collision_point()
		shadow_plane.global_transform.origin = collision_point

		# Adjust the shadow's orientation (if necessary)
		shadow_plane.look_at_from_position(collision_point + Vector3(0, 1, 0), collision_point)
		
		# Make the shadow visible when the raycast collides
		shadow_plane.visible = true
	else:
		# Hide the shadow if no collision is detected
		shadow_plane.visible = false
