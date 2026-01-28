shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float wave_progress : hint_range(0.0, 1.5) = 0.0;
uniform float wave_strength : hint_range(0.0, 0.1) = 0.03;
uniform float wave_thickness : hint_range(0.01, 0.3) = 0.08;
uniform vec2 wave_center = vec2(0.5, 0.5);

void fragment() {
    vec2 center = wave_center;
    vec2 uv = UV;
    
    // Distancia desde el centro
    float dist = distance(uv, center);
    
    // Radio de la onda actual
    float wave_radius = wave_progress * 0.7;
    
    // Calcular distancia al anillo
    float ring_dist = abs(dist - wave_radius);
    
    // Intensidad de la distorsión basada en proximidad al anillo
    float distortion_intensity = 0.0;
    if (ring_dist < wave_thickness) {
        float normalized_pos = ring_dist / wave_thickness;
        // Curva gaussiana para distorsión suave
        distortion_intensity = exp(-normalized_pos * normalized_pos * 8.0);
        // Mantener intensidad durante más tiempo
        distortion_intensity *= (1.0 - wave_progress * 0.6);
    }
    
    // Calcular dirección de distorsión (radial desde el centro)
    vec2 dir_from_center = normalize(uv - center);
    
    // Aplicar distorsión perpendicular y radial
    vec2 distortion = vec2(0.0);
    if (distortion_intensity > 0.01) {
        // Distorsión radial (empuja hacia afuera)
        distortion += dir_from_center * distortion_intensity * wave_strength;
        
        // Distorsión tangencial (crea efecto de remolino)
        vec2 tangent = vec2(-dir_from_center.y, dir_from_center.x);
        distortion += tangent * distortion_intensity * wave_strength * 0.5;
        
        // Agregar ondulación
        float angle = atan(dir_from_center.y, dir_from_center.x);
        float wave_pattern = sin(angle * 8.0 + wave_progress * 20.0);
        distortion += dir_from_center * wave_pattern * distortion_intensity * wave_strength * 0.3;
    }
    
    // Ajustar distorsión según el aspecto de la pantalla para que sea circular
    vec2 final_distortion = distortion;
    float aspect_ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
    final_distortion.y *= aspect_ratio;

    // Calcular UV para SCREEN_TEXTURE
    vec2 screen_uv = SCREEN_UV + final_distortion;
    
    // Obtener color de la pantalla con distorsión aplicada
    vec4 screen_color = texture(SCREEN_TEXTURE, screen_uv);
    
    // Opcional: agregar un leve brillo en el borde del anillo para que sea apenas visible
    float edge_glow = 0.0;
    if (distortion_intensity > 0.5) {
        edge_glow = (distortion_intensity - 0.5) * 0.3;
    }
    
    // Color final: imagen distorsionada con un toque de brillo
    COLOR = vec4(screen_color.rgb + vec3(edge_glow), 1.0);
}
