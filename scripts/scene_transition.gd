extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var loading_label: Label = $LoadingLabel
@onready var loading_indicator: AnimatedSprite2D = $LoadingIndicator
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Empezar invisible y sin bloquear clics
	color_rect.modulate.a = 0
	loading_label.modulate.a = 0
	loading_indicator.modulate.a = 0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

# Transición suave con fade (para menús)
func fade_to_scene(scene_path: String):
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # Bloquear clics durante transición
	animation_player.play("fade_out")
	await animation_player.animation_finished
	get_tree().change_scene_to_file(scene_path)
	animation_player.play("fade_in")
	await animation_player.animation_finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Permitir clics de nuevo

# Transición con pantalla de carga (para entrar/salir del juego)
func loading_screen_to_scene(scene_path: String, wait_time: float = 1.5):
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # Bloquear clics durante transición
	
	# Fade a negro instantáneo
	var tween_black = create_tween()
	tween_black.tween_property(color_rect, "modulate:a", 1.0, 0.3)
	await tween_black.finished
	
	# Mostrar y reproducir animación de carga
	loading_indicator.play()
	var tween = create_tween()
	tween.tween_property(loading_indicator, "modulate:a", 1.0, 0.3)
	await tween.finished
	
	# Esperar el tiempo especificado en la pantalla de carga
	await get_tree().create_timer(wait_time).timeout
	
	# Cambiar de escena
	get_tree().change_scene_to_file(scene_path)
	
	# Esperar un frame para que la nueva escena cargue
	await get_tree().process_frame
	
	# Ocultar indicador de carga
	var tween2 = create_tween()
	tween2.tween_property(loading_indicator, "modulate:a", 0.0, 0.3)
	await tween2.finished
	loading_indicator.stop()
	
	# Fade out de la pantalla negra
	var tween_fadeout = create_tween()
	tween_fadeout.tween_property(color_rect, "modulate:a", 0.0, 0.3)
	await tween_fadeout.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Permitir clics de nuevo
