extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var loading_label: Label = $LoadingLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Empezar invisible y sin bloquear clics
	color_rect.modulate.a = 0
	loading_label.modulate.a = 0
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
func loading_screen_to_scene(scene_path: String):
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # Bloquear clics durante transición
	animation_player.play("loading_start")
	await animation_player.animation_finished
	await get_tree().create_timer(1.0).timeout  # Esperar un segundo en la pantalla de carga
	get_tree().change_scene_to_file(scene_path)
	animation_player.play("loading_end")
	await animation_player.animation_finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Permitir clics de nuevo
