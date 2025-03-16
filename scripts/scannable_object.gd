extends StaticBody3D
class_name ScannableObject

@export var collection_data: Resource  # Type as Resource to avoid cyclic dependency
@export var scan_difficulty: float = 0.0  # 0.0 to 1.0
@export var display_label: String = ""  # Optional override for collection_data.label
@export_multiline var display_description: String = ""  # Optional override for collection_data.description

@onready var scan_highlight: OmniLight3D = $ScanHighlight
@onready var scan_indicator: GPUParticles3D = $ScanIndicator

var has_been_scanned: bool = false
var in_range: bool = false

func _ready() -> void:
	assert(collection_data != null and collection_data is CollectionItemData, 
		   "ScannableObject must have valid CollectionItemData resource!")
	
	# Use collection data if no overrides set
	if display_label.is_empty():
		display_label = collection_data.label
	if display_description.is_empty():
		display_description = collection_data.description

func get_scan_data() -> Dictionary:
	has_been_scanned = true
	scan_highlight.visible = false
	stop_scan_effect()
	
	return {
		"id": collection_data.id,  # Numeric ID for internal reference
		"label": display_label,  # Text for display
		"category": collection_data.category,  # Enum as int
		"description": display_description,
		"timestamp": Time.get_unix_time_from_system(),
		"location": global_position,
		"rarity_tier": collection_data.rarity_tier  # Numeric tier
	}

func highlight_in_range(is_in_range: bool) -> void:
	in_range = is_in_range
	scan_highlight.visible = is_in_range and not has_been_scanned
	scan_indicator.visible = is_in_range and not has_been_scanned

func start_scan_effect() -> void:
	if scan_indicator and not has_been_scanned:
		scan_indicator.emitting = true
		
func stop_scan_effect() -> void:
	if scan_indicator:
		scan_indicator.emitting = false
