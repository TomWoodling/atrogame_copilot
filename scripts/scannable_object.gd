extends StaticBody3D
class_name ScannableObject

@export var collection_data: CollectionItemData
@export var scan_difficulty: float = 0.0  # 0.0 to 1.0

@onready var scan_highlight: OmniLight3D = $ScanHighlight
@onready var scan_indicator: GPUParticles3D = $ScanIndicator
@onready var object_mesh: Node3D = $scannable_object



var has_been_scanned: bool = false
var in_range: bool = false

func _ready() -> void:
	if not collection_data:
		push_error("ScannableObject requires CollectionItemData resource")
		return
	
	if collection_data.category != 2:
		object_mesh.global_rotation.y = randi() % 360
	
	if collection_data.is_default == true:
		if $MeshInstance3D.get_surface_override_material(0) == null:
			var default_mat = StandardMaterial3D.new()
			default_mat.albedo_color = Color(0.7, 0.7, 0.8)
			default_mat.metallic = 0.3
			default_mat.roughness = 0.7
			$MeshInstance3D.set_surface_override_material(0, default_mat)

func get_scan_data() -> Dictionary:
	has_been_scanned = true
	scan_highlight.visible = false
	stop_scan_effect()
	return {
		"id": collection_data.id,
		"category": collection_data.category,
		"label": collection_data.label,
		"description": collection_data.description,
		"rarity_tier": collection_data.rarity_tier,
		"timestamp": Time.get_unix_time_from_system(),
		"location": global_position,
	}
	
func get_scan_difficulty() -> float:
	return scan_difficulty

func highlight_in_range(is_in_range: bool) -> void:
	in_range = is_in_range
	scan_highlight.visible = is_in_range and not has_been_scanned
	scan_indicator.visible = is_in_range and not has_been_scanned

func start_scan_effect() -> void:
	if scan_indicator:
		scan_indicator.visible = true
		scan_indicator.emitting = true
		
func stop_scan_effect() -> void:
	if scan_indicator:
		scan_indicator.emitting = false
		scan_indicator.visible = false
