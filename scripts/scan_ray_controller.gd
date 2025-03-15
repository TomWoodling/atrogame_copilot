extends RayCast3D

func _ready() -> void:
	# Connect to scanner manager signals
	ScannerManager.scan_started.connect(_on_scan_started)
	ScannerManager.scan_failed.connect(_on_scan_interrupted)
	ScannerManager.scan_completed.connect(_on_scan_completed)

func _input(event: InputEvent) -> void:
	if not GameManager.can_player_move():  # Use existing check for player state
		return
		
	if event.is_action_pressed("scan"):
		if is_colliding() and get_collider() is ScannableObject:
			var target = get_collider()
			ScannerManager.start_scan(target)
	elif event.is_action_released("scan"):
		if ScannerManager.is_scanning:
			ScannerManager.interrupt_scan("Scan cancelled")

func _on_scan_started(_target: Node3D) -> void:
	debug_shape_custom_color = Color(0, 1, 0, 0.5)  # Green for active scanning

func _on_scan_interrupted(_reason: String) -> void:
	debug_shape_custom_color = Color(1, 0, 0, 0.5)  # Red for interrupted

func _on_scan_completed(_target: Node3D, _data: Dictionary) -> void:
	debug_shape_custom_color = Color(0, 0, 1, 0.5)  # Blue for completed scan
