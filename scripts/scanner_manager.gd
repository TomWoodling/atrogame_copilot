extends Node

signal scan_started(target: Node3D)
signal scan_failed(reason: String)
signal scan_completed(target: Node3D, scan_data: Dictionary)

const SCAN_RANGE: float = 5.0  # Maximum scan distance

enum ScanCategory {
	EXOBIOLOGY,
	EXOBOTANY,
	EXOGEOLOGY,
	ARTIFACTS
}

var is_scanning: bool = false
var current_scan_target: Node3D = null
var scan_progress: float = 0.0
var scan_time: float = 2.0  # Base scan time

func _ready() -> void:
	# Scanner should process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _process(delta: float) -> void:
	if not is_scanning:
		return
		
	# Validate scanning state
	if GameManager.gameplay_state != GameManager.GameplayState.SCANNING:
		interrupt_scan("Scanning state mismatch")
		return
		
	# Validate target still exists
	if not is_instance_valid(current_scan_target):
		interrupt_scan("Target lost")
		return
		
	# Check range
	var distance = GameManager.player.global_position.distance_to(current_scan_target.global_position)
	if distance > SCAN_RANGE:
		interrupt_scan("Target out of range")
		return
	
	# Update scan progress
	scan_progress += delta / scan_time
	if scan_progress >= 1.0:
		_complete_scan()

func start_scan(target: Node3D) -> void:
	if is_scanning or not _can_scan(target):
		return
		
	# Tell GameManager to enter scanning state
	GameManager.gameplay_state = GameManager.GameplayState.SCANNING
	is_scanning = true
	current_scan_target = target
	scan_progress = 0.0
	
	# Calculate scan time based on difficulty
	var difficulty_modifier = 1.0
	if target is ScannableObject:
		difficulty_modifier = 1.0 + target.scan_difficulty
	scan_time = 2.0 * difficulty_modifier
	
	# Start visual effects
	if target.has_method("start_scan_effect"):
		target.start_scan_effect()
	
	scan_started.emit(target)

func interrupt_scan(reason: String = "Scan interrupted") -> void:
	if not is_scanning:
		return
		
	# Clean up scanning state
	GameManager.gameplay_state = GameManager.GameplayState.NORMAL
	
	# Stop visual effects
	if is_instance_valid(current_scan_target) and current_scan_target.has_method("stop_scan_effect"):
		current_scan_target.stop_scan_effect()
	
	is_scanning = false
	current_scan_target = null
	scan_progress = 0.0
	
	scan_failed.emit(reason)

func _complete_scan() -> void:
	if not is_instance_valid(current_scan_target):
		interrupt_scan("Target invalid")
		return
		
	# Get scan data from target
	var scan_data = {}
	if current_scan_target.has_method("get_scan_data"):
		scan_data = current_scan_target.get_scan_data()
	else:
		interrupt_scan("Invalid scan target")
		return
	
	scan_completed.emit(current_scan_target, scan_data)
	
	# Reset scanner state
	GameManager.gameplay_state = GameManager.GameplayState.NORMAL
	is_scanning = false
	current_scan_target = null
	scan_progress = 0.0

func _can_scan(target: Node3D) -> bool:
	# Check game state
	if GameManager.gameplay_state != GameManager.GameplayState.NORMAL:
		return false
		
	# Check target validity
	if not is_instance_valid(target) or not target is ScannableObject:
		return false
		
	# Check range
	var distance = GameManager.player.global_position.distance_to(target.global_position)
	if distance > SCAN_RANGE:
		return false
	
	return true

# Helper function to get current scan progress (0.0 to 1.0)
func get_scan_progress() -> float:
	return scan_progress if is_scanning else 0.0

# Helper function to get current scan range
func get_scan_range() -> float:
	return SCAN_RANGE
