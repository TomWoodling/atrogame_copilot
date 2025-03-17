extends RayCast3D

func _ready() -> void:
	# Add to group so ScannerManager can find us
	add_to_group("scan_ray")
	
	# Connect to scanner manager signals
	ScannerManager.scan_started.connect(_on_scan_started)
	ScannerManager.scan_failed.connect(_on_scan_interrupted)
	ScannerManager.scan_completed.connect(_on_scan_completed)
	
	# Debug print to confirm initialization
	print("Scan ray controller initialized")

func _input(event: InputEvent) -> void:
	if not GameManager.can_player_move():  # Use existing check for player state
		print("Player movement blocked")
		return
		
	if event.is_action_pressed("scan"):
		print("Scan action pressed")
		print("Is colliding: ", is_colliding())
		if is_colliding():
			var collider = get_collider()
			print("Collider: ", collider)
			print("Is ScannableObject: ", collider is ScannableObject)
			if collider is ScannableObject:
				var target = collider as ScannableObject
				print("Collection data: ", target.collection_data)
				ScannerManager.start_scan(target)
	elif event.is_action_released("scan"):
		if ScannerManager.is_scanning:
			ScannerManager.interrupt_scan("Scan cancelled")

func _on_scan_started(_target: Node3D) -> void:
	print("Scan started signal received")
	debug_shape_custom_color = Color(0, 1, 0, 0.5)  # Green for active scanning

func _on_scan_interrupted(_reason: String) -> void:
	print("Scan interrupted: ", _reason)
	debug_shape_custom_color = Color(1, 0, 0, 0.5)  # Red for interrupted

func _on_scan_completed(_target: Node3D, _data: Dictionary) -> void:
	print("Scan completed")
	debug_shape_custom_color = Color(0, 0, 1, 0.5)  # Blue for completed scan
