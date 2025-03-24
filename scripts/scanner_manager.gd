extends Node

signal scan_started(target: Node3D)
signal scan_completed(target: Node3D, data: Dictionary)
signal scan_failed(reason: String)

const SCAN_RANGE: float = 5.0
const SCAN_TIME: float = 2.0

var is_scanning: bool = false
var scan_progress: float = 0.0
var current_target: Node3D = null
var scan_ray: RayCast3D  # Reference to the scan ray

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("gameplay_pause")
	# We'll get the scan ray reference when it's ready
	call_deferred("_setup_scan_ray")

func _setup_scan_ray() -> void:
	# Find the scan ray in the scene - adjust the path as needed
	scan_ray = get_tree().get_first_node_in_group("scan_ray") as RayCast3D
	if not scan_ray:
		push_error("ScannerManager: No scan ray found in scene!")

func _process(delta: float) -> void:
	if not is_scanning or not current_target or ProcessManager.is_gameplay_blocked():
		return
		
	# Check if target is still in range and visible
	if not _is_target_valid(current_target):
		interrupt_scan("Target lost")
		return
		
	scan_progress += delta / SCAN_TIME
	if scan_progress >= 1.0:
		_complete_scan()

func _is_target_valid(target: Node3D) -> bool:
	if not is_instance_valid(target):
		return false
	
	# Check if target is still in range
	var distance = target.global_position.distance_to(GameManager.player.global_position)
	if distance > SCAN_RANGE:
		return false
	
	# Check if target is still visible via raycast
	return scan_ray and scan_ray.is_colliding() and scan_ray.get_collider() == target

func start_scan(target: Node3D) -> void:
	if not target is ScannableObject or ProcessManager.is_gameplay_blocked():
		return
		
	if not _is_target_valid(target):
		scan_failed.emit("Target not in range or not visible")
		return
		
	if not target.collection_data:
		scan_failed.emit("Invalid scan target - no collection data")
		return
		
	current_target = target
	is_scanning = true
	scan_progress = 0.0
	GameManager.start_scanning()
	scan_started.emit(target)
	target.start_scan_effect()

func _complete_scan() -> void:
	if not current_target or not current_target.collection_data:
		interrupt_scan("Invalid scan target")
		return
		
	var scan_data = {
		"id": current_target.collection_data.id,
		"category": current_target.collection_data.category,
		"label": current_target.collection_data.label,
		"description": current_target.collection_data.description,
		"icon_path": current_target.collection_data.icon_path,
		"rarity_tier": current_target.collection_data.rarity_tier,
		"timestamp": Time.get_unix_time_from_system()
	}
	scan_completed.emit(current_target, scan_data)
	
	# Convert CollectionItemData resource to Dictionary for InventoryManager
	var collection_dict = {
		"id": current_target.collection_data.id,
		"category": current_target.collection_data.category,
		"label": current_target.collection_data.label,
		"description": current_target.collection_data.description,
		"icon_path": current_target.collection_data.icon_path,
		"rarity_tier": current_target.collection_data.rarity_tier
	}
	
	# Let InventoryManager handle the collection update
	InventoryManager.add_collected_item(collection_dict)
	
	_reset_scan()
	GameManager.stop_scanning()

func interrupt_scan(reason: String = "Scan interrupted") -> void:
	_reset_scan()
	GameManager.stop_scanning()
	scan_failed.emit(reason)

func _reset_scan() -> void:
	is_scanning = false
	scan_progress = 0.0
	current_target = null
