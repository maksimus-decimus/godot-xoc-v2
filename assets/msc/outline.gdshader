shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0);
uniform float line_thickness : hint_range(0, 10) = 1.0;
uniform bool blinking = false;
uniform float blink_speed = 10.0;
uniform bool invert_colors = false;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE;
    
    float alpha = 0.0;
    
    // Muestreo radial mejorado para evitar el efecto pixelado "cuadrado"
    // Usamos más muestras en un círculo perfecto
    int samples = 12; // Cantidad de muestras (ajustable rendimiento/calidad)
    float step_angle = 6.2831853 / float(samples); // 2*PI / muestras
    
    for (int i = 0; i < samples; i++) {
        float angle = float(i) * step_angle;
        vec2 offset = vec2(cos(angle), sin(angle)) * line_thickness;
        alpha += texture(TEXTURE, UV + offset * size).a;
    }
    
    // En lugar de acumular ciegamente, buscamos el valor máximo de alfa alrededor
    // para mantener la forma, o promediamos para suavizar.
    // Para contornos nítidos pero curvos (sin dientes de sierra de 8 direcciones),
    // limitar el alfa ayuda.
    
    // Normalizar alpha en base a muestras para suavizar bordes (anti-aliasing)
    // Si queremos un borde más duro pero con forma correcta:
    // float outline_alpha = clamp(alpha, 0.0, 1.0);
    
    // Si queremos suavizado (anti-aliasing):
    float outline_alpha = smoothstep(0.0, 3.0, alpha); // Umbral suave
    outline_alpha = clamp(outline_alpha, 0.0, 1.0);
    
    vec4 color = texture(TEXTURE, UV);
    
    // Gestión del color y parpadeo
    vec4 final_line_color = line_color;
    if (blinking) {
        float blink = (sin(TIME * blink_speed) + 1.0) * 0.5;
        final_line_color = mix(line_color, vec4(1.0, 1.0, 1.0, 1.0), blink);
    }
    
    final_line_color.a = outline_alpha;
    
    // Mezcla final: Sprite original sobre el contorno
    // Usamos mix para transiciones suaves en los bordes del sprite original
    
    vec4 final_sprite_color = color;
    
    // Inversión de colores (si blinking es true + flag especial o usando otro uniform, 
    // pero para eficiencia usaremos una lógica simple: si blinking es true Y un parametro extra...
    // Mejor añadimos un uniform explícito para inversión)
    
    // NOTA: Añadiremos el uniform arriba primero.
    
    if (invert_colors) {
        final_sprite_color.rgb = vec3(1.0) - final_sprite_color.rgb;
    }
    
    COLOR = mix(final_line_color, final_sprite_color, color.a);
}
