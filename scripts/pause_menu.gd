extends CanvasLayer

signal continue_pressed
signal quit_pressed

var pausa_audio_player: AudioStreamPlayer
@onready var god_mode_button = $CenterContainer/VBoxContainer/GodModeButton
@onready var debug_button = $CenterContainer/VBoxContainer/DebugButton

# Sistema de randomización sin repetición
var pausa_sounds_pool: Array = []
var continue_sounds_pool: Array = []

# Listas de sonidos
const PAUSA_FILES = [
	"res://sound/announcer/pausa/pausa_1.wav",
	"res://sound/announcer/pausa/pausa_2.wav",
	"res://sound/announcer/pausa/pausa_3.wav"
]

const CONTINUE_FILES = [
	"res://sound/announcer/lets_rock.wav",
	"res://sound/announcer/lets_rock2.wav",
	"res://sound/announcer/lets_rock3.wav",
	"res://sound/announcer/action/continuar.wav",
	"res://sound/announcer/action/continuar_1.wav"
]

func _ready() -> void:
	# Ocultar menú de pausa al inicio
	visible = false
	
	# Crear audio player para sonidos de pausa
	pausa_audio_player = AudioStreamPlayer.new()
	add_child(pausa_audio_player)
	
	# Inicializar pools de sonidos
	_reset_pausa_pool()
	_reset_continue_pool()

# Función para resetear el pool de sonidos de pausa
func _reset_pausa_pool() -> void:
	pausa_sounds_pool.clear()
	pausa_sounds_pool.append_array(PAUSA_FILES.duplicate())
	pausa_sounds_pool.shuffle()

# Función para resetear el pool de sonidos de continuar
func _reset_continue_pool() -> void:
	continue_sounds_pool.clear()
	continue_sounds_pool.append_array(CONTINUE_FILES.duplicate())
	continue_sounds_pool.shuffle()

# Función para obtener un sonido sin repetición
func _get_random_sound(pool: Array, reset_func: Callable) -> String:
	if pool.is_empty():
		reset_func.call()
	
	return pool.pop_front()

func show_pause_menu() -> void:
	visible = true
	get_tree().paused = true
	
	# Actualizar texto del botón God Mode
	if god_mode_button:
		if Global.god_mode:
			god_mode_button.text = "God Mode: ON"
			god_mode_button.modulate = Color.GREEN
		else:
			god_mode_button.text = "God Mode: OFF"
			god_mode_button.modulate = Color.WHITE
	
	# Actualizar texto del botón Debug One-Hit Kill
	if debug_button:
		if Global.debug_one_hit_kill:
			debug_button.text = "DEBUG: One-Hit Kill ON"
			debug_button.modulate = Color.RED
		else:
			debug_button.text = "DEBUG: One-Hit Kill OFF"
			debug_button.modulate = Color.WHITE
	
	# Reproducir sonido aleatorio de pausa (sin repetición)
	var random_pausa = _get_random_sound(pausa_sounds_pool, _reset_pausa_pool)
	pausa_audio_player.stream = load(random_pausa)
	pausa_audio_player.play()

func hide_pause_menu() -> void:
	visible = false
	get_tree().paused = false

func _on_continue_button_pressed() -> void:
	UISounds.play_select()
	# Reproducir sonido aleatorio de continuar (sin repetición)
	var random_continue = _get_random_sound(continue_sounds_pool, _reset_continue_pool)
	pausa_audio_player.stream = load(random_continue)
	pausa_audio_player.play()
	
	# Esperar a que termine el audio antes de reanudar
	await pausa_audio_player.finished
	
	hide_pause_menu()
	continue_pressed.emit()

func _on_quit_button_pressed() -> void:
	UISounds.play_cancel()
	hide_pause_menu()
	quit_pressed.emit()

func _on_god_mode_button_pressed() -> void:
	UISounds.play_select()
	Global.god_mode = !Global.god_mode
	
	# Si se activa God Mode, desactivar One-Hit Kill
	if Global.god_mode and Global.debug_one_hit_kill:
		Global.debug_one_hit_kill = false
		if debug_button:
			debug_button.text = "DEBUG: One-Hit Kill OFF"
			debug_button.modulate = Color.WHITE
	
	# Actualizar texto del botón
	if god_mode_button:
		if Global.god_mode:
			god_mode_button.text = "God Mode: ON"
			god_mode_button.modulate = Color.GREEN
		else:
			god_mode_button.text = "God Mode: OFF"
			god_mode_button.modulate = Color.WHITE
	
	print("God Mode: ", "ACTIVADO" if Global.god_mode else "DESACTIVADO")

func _on_debug_button_pressed() -> void:
	UISounds.play_select()
	Global.debug_one_hit_kill = !Global.debug_one_hit_kill
	
	# Si se activa One-Hit Kill, desactivar God Mode
	if Global.debug_one_hit_kill and Global.god_mode:
		Global.god_mode = false
		if god_mode_button:
			god_mode_button.text = "God Mode: OFF"
			god_mode_button.modulate = Color.WHITE
	
	# Actualizar texto del botón
	if debug_button:
		if Global.debug_one_hit_kill:
			debug_button.text = "DEBUG: One-Hit Kill ON"
			debug_button.modulate = Color.RED
		else:
			debug_button.text = "DEBUG: One-Hit Kill OFF"
			debug_button.modulate = Color.WHITE
	
	print("Debug One-Hit Kill: ", "ACTIVADO" if Global.debug_one_hit_kill else "DESACTIVADO")
