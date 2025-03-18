shader_type spatial;

uniform vec4 planet_color_1 : source_color = vec4(0.2, 0.4, 0.6, 1.0);
uniform vec4 planet_color_2 : source_color = vec4(0.1, 0.2, 0.5, 1.0);
uniform vec4 atmosphere_color : source_color = vec4(0.5, 0.2, 0.7, 1.0);
uniform float atmosphere_rim_power = 3.0;
uniform float atmosphere_intensity = 1.5;
uniform sampler2D noise_texture;
uniform float noise_scale = 2.0;
uniform float time_scale = 0.1;

varying vec3 normal_interp;
varying vec3 view_dir;

void vertex() {
    normal_interp = NORMAL;
    view_dir = normalize(VERTEX);
}

void fragment() {
    // Create base planet color with noise patterns
    vec2 uv = UV * noise_scale;
    uv.y += TIME * time_scale;
    float noise_val = texture(noise_texture, uv).r;
    
    // Create bands and patterns
    float band = sin(UV.y * 10.0 + noise_val) * 0.5 + 0.5;
    vec4 planet_color = mix(planet_color_1, planet_color_2, band);
    
    // Apply atmospheric rim
    float fresnel = pow(1.0 - dot(normal_interp, view_dir), atmosphere_rim_power);
    vec4 final_color = mix(planet_color, atmosphere_color * atmosphere_intensity, fresnel);
    
    // Output with emissive component
    ALBEDO = final_color.rgb;
    EMISSION = atmosphere_color.rgb * fresnel * atmosphere_intensity;
    
    // Add metallic and roughness variation
    METALLIC = 0.1 + noise_val * 0.1;
    ROUGHNESS = 0.7 - noise_val * 0.3;
}