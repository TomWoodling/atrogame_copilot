extends Node

signal scan_started(object: Node3D)
signal scan_completed(object: Node3D, data: Dictionary)
signal scan_failed(reason: String)

enum ScanCategory {
	EXOBIOLOGY,
	EXOBOTANY,
	EXOGEOLOGY,
	ARTIFACTS
}

const SCAN_RANGE: float = 10.0
const MIN_SCAN_TIME: float = 0.5
const MAX_SCAN_TIME: float = 2.0

var is_scanning: bool = false
var current_scan_target: Node3D = null
var scan_progress: float = 0.0
var scan_time: float = 0.0

# Dictionary to track what's been scanned
var scanned_objects: Dictionary = {}

func _ready() -> void:
	GameManager.game_state_changed.connect(_on_game_state_changed)

func start_scan(target: Node3D) -> void:
	if is_scanning or not _can_scan(target):
		return
		
	if not target.has_method("get_scan_data"):
		scan_failed.emit("Object cannot be scanned")
		return
		
	var distance = GameManager.player.global_position.distance_to(target.global_position)
	if distance > SCAN_RANGE:
		scan_failed.emit("Target out of range")
		return
		
	is_scanning = true
	current_scan_target = target
	scan_progress = 0.0
	scan_time = _calculate_scan_time(target)
	scan_started.emit(target)
	print("scan started")

func interrupt_scan(reason: String = "Scan interrupted") -> void:
	if is_scanning:
		is_scanning = false
		current_scan_target = null
		scan_progress = 0.0
		scan_failed.emit(reason)

func _process(delta: float) -> void:
	if not is_scanning or not _can_scan(current_scan_target):
		return
		
	if not is_instance_valid(current_scan_target):
		interrupt_scan("Target lost")
		return
		
	var distance = GameManager.player.global_position.distance_to(current_scan_target.global_position)
	if distance > SCAN_RANGE:
		interrupt_scan("Target out of range")
		return
		
	# Check if player is still in valid scanning state
	if not GameManager.player.can_start_scan() or GameManager.player.velocity.length() > GameManager.player.scan_stability_threshold:
		interrupt_scan("Movement interrupted scan")
		return
		
	scan_progress += delta / scan_time
	
	if scan_progress >= 1.0:
		_complete_scan()

func _cancel_scan(reason: String = "") -> void:
	if is_scanning:
		interrupt_scan(reason)

func _complete_scan() -> void:
	if not current_scan_target:
		return
		
	var scan_data = current_scan_target.get_scan_data()
	scanned_objects[current_scan_target.get_instance_id()] = scan_data
	
	scan_completed.emit(current_scan_target, scan_data)
	
	# Add to inventory if it's a collectible
	if scan_data.has("category"):
		InventoryManager.add_scanned_item(scan_data)
	
	is_scanning = false
	current_scan_target = null
	scan_progress = 0.0
	print("scan ended")

func _calculate_scan_time(target: Node3D) -> float:
	# Base scan time can be modified by object properties
	var base_time = MIN_SCAN_TIME
	if target.has_method("get_scan_difficulty"):
		base_time += target.get_scan_difficulty() * (MAX_SCAN_TIME - MIN_SCAN_TIME)
	return base_time

func _can_scan(target: Node3D = null) -> bool:
	# Global game state check
	if not (GameManager.current_state == GameManager.GameState.PLAYING and 
			GameManager.gameplay_state == GameManager.GameplayState.NORMAL):
		return false

	# Player state check
	if not is_instance_valid(GameManager.player):
		return false
		
	if not GameManager.player.can_start_scan():
		return false

	# Target validation (if provided)
	if target != null:
		if not target.has_method("get_scan_data"):
			return false
			
		var distance = GameManager.player.global_position.distance_to(target.global_position)
		if distance > SCAN_RANGE:
			return false
	
	return true

func _on_game_state_changed(_new_state: int) -> void:
	if is_scanning:
		interrupt_scan("Game state changed")

func _validate_scanning_state() -> bool:
	if not is_scanning or not current_scan_target:
		return false
		
	if not is_instance_valid(current_scan_target):
		interrupt_scan("Target lost")
		return false
		
	var distance = GameManager.player.global_position.distance_to(current_scan_target.global_position)
	if distance > SCAN_RANGE:
		interrupt_scan("Target out of range")
		return false
		
	if not GameManager.can_player_move():
		interrupt_scan("Invalid player state")
		return false
		
	return true

func is_object_scanned(object_id: int) -> bool:
	return scanned_objects.has(object_id)

func get_scan_data(object_id: int) -> Dictionary:
	if scanned_objects.has(object_id):
		return scanned_objects[object_id]
	return {}

func get_scan_progress() -> float:
	return scan_progress if is_scanning else 0.0

func get_remaining_scan_time() -> float:
	if not is_scanning:
		return 0.0
	return (1.0 - scan_progress) * scan_time

func force_complete_scan() -> void:
	if is_scanning and is_instance_valid(current_scan_target):
		_complete_scan()
