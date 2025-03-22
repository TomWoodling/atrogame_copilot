extends CSGBox3D

@export var texture : Texture2D
@export var curvature : float = 1.0  # Curvature strength
@export var tile_factor : float = 10.0  # Tiling factor for UV0

func _ready():
	# Create a new ShaderMaterial
	var shader_material = ShaderMaterial.new()

	# Create the shader code
	var shader_code = """
	shader_type spatial;

	uniform sampler2D texture;
	uniform float curvature : hint_range(0.0, 1.0) = 0.2;
	uniform float tile_factor : hint_range(1.0, 100.0) = 1.0;

	void fragment() {
		vec2 tiled_uv = UV * tile_factor;  // Apply tiling using UV0
		vec2 curved_uv = tiled_uv;
		float distance_from_center = length(curved_uv - vec2(0.5));  // Get distance from the center
		curved_uv = (curved_uv - 0.4) / (1.0 + curvature * distance_from_center) + 0.4;

		vec4 tex_color = texture(texture, curved_uv);
		ALBEDO = tex_color.rgb;
		ALPHA = tex_color.a;
	}
	"""
	
	# Create a new shader and assign the code
	var shader = Shader.new()
	shader.set_code(shader_code)

	# Assign the shader to the ShaderMaterial
	shader_material.shader = shader

	# Set the texture, curvature, and tile factor parameters
	shader_material.set_shader_parameter("texture", texture)
	shader_material.set_shader_parameter("curvature", curvature)
	shader_material.set_shader_parameter("tile_factor", tile_factor)

	# Apply the material to the CSGBox3D
	material_override = shader_material
