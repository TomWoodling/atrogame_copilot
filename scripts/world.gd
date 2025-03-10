extends Node3D

@onready var player : Node3D = $player

func _ready() -> void:
	# Ensure managers are initialized
	if not GameManager.is_initialized:
		GameManager.initialize()

	
	GameManager.player = player
	# Setup additional environment parameters
	setup_environment()

func setup_environment() -> void:
	# Get existing WorldEnvironment node
	var world_env = $WorldEnvironment
	if not world_env or not world_env.environment:
		push_error("World environment not properly set up")
		return
		
	# Enhance the existing environment while preserving the sky shader
	var env = world_env.environment
	
	# Adjust fog for better distance culling
	env.fog_enabled = true
	env.fog_density = 0.01
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.01
	env.volumetric_fog_albedo = Color(0.05, 0.05, 0.1)
	
	# Enhance lighting
	var sun = $DirectionalLight3D
	if sun:
		sun.light_energy = 1.2
		sun.light_color = Color(1.0, 0.98, 0.9)  # Slightly warm sunlight
		sun.shadow_enabled = true
		sun.shadow_bias = 0.03
		sun.directional_shadow_max_distance = 200.0
		
	# Add some subtle ambient occlusion
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 1.0
	env.ssao_power = 1.5
	env.ssao_detail = 1.0
	env.ssao_horizon = 0.06
	env.ssao_sharpness = 0.98
	
	# Adjust tonemap for better space visuals
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.0
	
	# Add subtle glow for space effects
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.0
	env.glow_bloom = 0.1
	env.glow_hdr_threshold = 1.0
	
	# Remove the temporary holding area once the world is generated
	var holding_area = $holdingArea
	if holding_area:
		# Wait a short moment to ensure world generation has started
		await get_tree().create_timer(0.5).timeout
		holding_area.queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.pause_game()
		else:
			GameManager.resume_game()
