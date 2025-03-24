# encounter_stage.gd (modified)
extends StaticBody3D

signal challenge_item_collected(item_id: String)
signal challenge_destination_reached
signal challenge_time_elapsed

# Challenge objects
const COLLECTION_ITEM = preload("res://scenes/challenge_collectable.tscn")
const DESTINATION_MARKER = preload("res://scenes/destination_marker.tscn")

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var timer: Timer = $Timer

# Challenge configuration
var challenge_type: EncounterManager.ChallengeType
var challenge_config: Dictionary
var item_count: int = 0
var collected_count: int = 0
var time_limit: float = 0
var time_remaining: float = 0
var is_active: bool = false

# Collection of all spawned objects
var challenge_objects: Array[Node3D] = []

func _ready() -> void:
	# Initialize timer
	if not has_node("Timer"):
		var new_timer = Timer.new()
		new_timer.name = "Timer"
		add_child(new_timer)
		timer = new_timer
	
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)

func setup_challenge(type: EncounterManager.ChallengeType, config: Dictionary) -> void:
	# Store challenge configuration
	challenge_type = type
	challenge_config = config
	
	# Resize stage based on challenge type
	var stage_size := _get_stage_size(type)
	if not _resize_stage(stage_size):
		push_error("Failed to resize challenge stage")
		return
	
	# Create challenge objects based on type
	match type:
		EncounterManager.ChallengeType.COLLECTION:
			_setup_collection_challenge(config)
		EncounterManager.ChallengeType.PLATFORMING:
			_setup_platforming_challenge(config)
		EncounterManager.ChallengeType.TIMED_TASK:
			_setup_timed_challenge(config)
		EncounterManager.ChallengeType.PUZZLE:
			_setup_puzzle_challenge(config)
	
	# Set up time limit if applicable
	if config.has("time_limit") and config.time_limit > 0:
		time_limit = config.time_limit
		time_remaining = time_limit
	
	# Activate the challenge
	activate()

func activate() -> void:
	is_active = true
	
	# Start timer if time-limited
	if time_limit > 0:
		timer.start(1.0)  # Update every second
		
		# Show initial time
		HUDManager.show_message({
			"text": "Time remaining: " + str(int(time_remaining)) + "s",
			"color": Color.YELLOW,
			"duration": 1.0
		})

func deactivate() -> void:
	is_active = false
	timer.stop()
	
	# Clean up challenge objects
	cleanup()

func _setup_collection_challenge(config: Dictionary) -> void:
	# Get params with defaults
	item_count = config.get("count", 5)
	var spawn_radius = config.get("radius", 10.0)
	
	# Create collection items
	for i in range(item_count):
		var item = COLLECTION_ITEM.instantiate()
		add_child(item)
		
		# Random position within radius
		var angle = randf() * TAU
		var distance = randf_range(2.0, spawn_radius)
		var pos = Vector3(cos(angle) * distance, 1.0, sin(angle) * distance)
		item.position = pos
		
		# Connect signals
		if item.has_signal("collected"):
			item.connect("collected", _on_item_collected)
		
		challenge_objects.append(item)

func _setup_platforming_challenge(config: Dictionary) -> void:
	# Get params with defaults
	var destination_distance = config.get("distance", 15.0)
	var platform_count = config.get("platform_count", 5)
	
	# Create destination marker
	var destination = DESTINATION_MARKER.instantiate()
	add_child(destination)
	
	# Position at a specific distance, potentially elevated
	var angle = randf() * TAU
	var pos = Vector3(cos(angle) * destination_distance, config.get("height", 5.0), sin(angle) * destination_distance)
	destination.position = pos
	
	# Connect signals
	if destination.has_signal("reached"):
		destination.connect("reached", _on_destination_reached)
	
	challenge_objects.append(destination)
	
	# Create platforms leading to destination
	# (Platform creation code would go here)

func _setup_timed_challenge(config: Dictionary) -> void:
	# Implementation depends on the specific timed challenge type
	pass

func _setup_puzzle_challenge(config: Dictionary) -> void:
	# Implementation depends on the puzzle design
	pass

func _on_item_collected(item_id: String) -> void:
	collected_count += 1
	emit_signal("challenge_item_collected", item_id)
	
	# Update HUD
	HUDManager.show_message({
		"text": "Collected " + str(collected_count) + "/" + str(item_count),
		"color": Color.GREEN,
		"duration": 1.0
	})
	
	# Check if all items collected
	if collected_count >= item_count:
		# Complete the challenge
		EncounterManager.complete_challenge(true)

func _on_destination_reached() -> void:
	emit_signal("challenge_destination_reached")
	
	# Complete the challenge
	EncounterManager.complete_challenge(true)

func _on_timer_timeout() -> void:
	time_remaining -= 1.0
	
	# Update HUD with time remaining
	if time_remaining > 0:
		if time_remaining <= 10:  # Last 10 seconds
			HUDManager.show_message({
				"text": "Time remaining: " + str(int(time_remaining)) + "s",
				"color": Color.RED if time_remaining <= 5 else Color.YELLOW,
				"duration": 0.5
			})
	else:
		# Time's up!
		emit_signal("challenge_time_elapsed")
		
		# Fail the challenge if time-based
		var fail_on_timeout = challenge_config.get("fail_on_timeout", true)
		if fail_on_timeout:
			EncounterManager.complete_challenge(false)
		
		# Stop the timer
		timer.stop()

func _get_stage_size(type: EncounterManager.ChallengeType) -> Vector2:
	match type:
		EncounterManager.ChallengeType.COLLECTION: 
			return Vector2(20.0, 20.0)
		EncounterManager.ChallengeType.PLATFORMING: 
			return Vector2(30.0, 30.0)
		EncounterManager.ChallengeType.TIMED_TASK: 
			return Vector2(15.0, 15.0)
		EncounterManager.ChallengeType.PUZZLE: 
			return Vector2(25.0, 25.0)
		_: 
			return Vector2(10.0, 10.0)

func _resize_stage(size: Vector2) -> bool:
	# Reuse your existing resize code
	# ...
	return true  # Return success/failure

func cleanup() -> void:
	# Clean up all spawned challenge objects
	for obj in challenge_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	
	challenge_objects.clear()
