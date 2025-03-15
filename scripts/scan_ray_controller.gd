extends RayCast3D

func _ready() -> void:
	# Connect to input and GameManager signals
	GameManager.scan_started.connect(_on_scan_started)
	GameManager.scan_interrupted.connect(_on_scan_interrupted)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("scan"):  # Assuming "scan" action is mapped to F
		if GameManager.gameplay_state == GameManager.GameplayState.NORMAL:
			if is_colliding() and get_collider() is ScannableObject:
				GameManager.start_scanning()
				ScannerManager.start_scan(get_collider())
	elif event.is_action_released("scan"):
		if GameManager.gameplay_state == GameManager.GameplayState.SCANNING:
			GameManager.stop_scanning()
			ScannerManager.interrupt_scan()

func _on_scan_started() -> void:
	# Optional: Visual feedback that scanning has started
	debug_shape_custom_color = Color(0, 1, 0, 0.5)

func _on_scan_interrupted() -> void:
	# Reset visual state
	debug_shape_custom_color = Color(0.2, 0.8, 1.0, 0.5)
