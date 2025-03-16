extends Node

signal scan_started(target: Node3D)
signal scan_completed(target: Node3D, data: Dictionary)
signal scan_failed(reason: String)

const SCAN_RANGE: float = 5.0
const SCAN_TIME: float = 2.0

var is_scanning: bool = false
var scan_progress: float = 0.0
var current_target: Node3D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("gameplay_pause")

func _process(delta: float) -> void:
	if not is_scanning or not current_target or ProcessManager.is_gameplay_blocked():
		return
		
	scan_progress += delta / SCAN_TIME
	if scan_progress >= 1.0:
		_complete_scan()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("scan") and GameManager.current_state == GameManager.GameState.PLAYING:
		if not is_scanning:
			GameManager.start_scanning()
			_attempt_scan()
		else:
			_interrupt_scan()

func _attempt_scan() -> void:
	var target = _find_scannable_target()
	if target:
		start_scan(target)
	else:
		scan_failed.emit("No scannable object in range")
		GameManager.stop_scanning()

func start_scan(target: Node3D) -> void:
	if not target is ScannableObject or ProcessManager.is_gameplay_blocked():
		return
		
	current_target = target
	is_scanning = true
	scan_progress = 0.0
	scan_started.emit(target)

func _complete_scan() -> void:
	if not current_target:
		return
		
	var scan_data = {
		"name": current_target.object_name,
		"category": current_target.category,
		"type": current_target.object_type,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	scan_completed.emit(current_target, scan_data)
	InventoryManager.add_scanned_item(current_target.object_type, current_target.category)
	
	_reset_scan()
	GameManager.stop_scanning()

func _interrupt_scan() -> void:
	_reset_scan()
	GameManager.stop_scanning()
	scan_failed.emit("Scan interrupted")

func _reset_scan() -> void:
	is_scanning = false
	scan_progress = 0.0
	current_target = null

func _find_scannable_target() -> Node3D:
	# Implementation will depend on your raycasting setup
	# This should return the nearest scannable object in range
	return null
