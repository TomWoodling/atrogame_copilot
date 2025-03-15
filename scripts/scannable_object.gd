extends StaticBody3D
class_name ScannableObject

@export_enum("Exobiology", "Exobotany", "Exogeology", "Artifacts") var scan_category: int = 0
@export var scan_difficulty: float = 0.0  # 0.0 to 1.0
@export var object_name: String = "Unknown Object"
@export_multiline var description: String = "No data available"

@onready var scan_highlight: OmniLight3D = $ScanHighlight
@onready var scan_indicator: GPUParticles3D = $ScanIndicator

var has_been_scanned: bool = false
var in_range: bool = false

func _ready() -> void:
	# Set up default material if none provided
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
		"name": object_name,
		"category": ScannerManager.ScanCategory.values()[scan_category],
		"description": description,
		"timestamp": Time.get_unix_time_from_system(),
		"location": global_position,
	}
	
func get_scan_difficulty() -> float:
	return scan_difficulty

func highlight_in_range(is_in_range: bool) -> void:
	in_range = is_in_range
	scan_highlight.visible = is_in_range and not has_been_scanned
	scan_indicator.visible = is_in_range and not has_been_scanned

# Add these methods to the existing scannable_object.gd
func start_scan_effect() -> void:
	if scan_indicator:
		scan_indicator.emitting = true
		
func stop_scan_effect() -> void:
	if scan_indicator:
		scan_indicator.emitting = false
