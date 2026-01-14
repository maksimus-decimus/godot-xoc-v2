extends CanvasLayer

signal continue_pressed
signal quit_pressed

var pausa_audio_player: AudioStreamPlayer

func _ready() -> void:
	# Ocultar menú de pausa al inicio
	visible = false
	
	# Crear audio player para sonidos de pausa
	pausa_audio_player = AudioStreamPlayer.new()
	add_child(pausa_audio_player)

func show_pause_menu() -> void:
	visible = true
	get_tree().paused = true
	
	# Reproducir sonido aleatorio de pausa
	var pausa_files = [
		"res://sound/announcer/pausa/pausa_1.wav",
		"res://sound/announcer/pausa/pausa_2.wav",
		"res://sound/announcer/pausa/pausa_3.wav"
	]
	
	var random_pausa = pausa_files[randi() % pausa_files.size()]
	pausa_audio_player.stream = load(random_pausa)
	pausa_audio_player.play()

func hide_pause_menu() -> void:
	visible = false
	get_tree().paused = false

func _on_continue_button_pressed() -> void:
	# Reproducir sonido aleatorio de "lets rock" al continuar
	var lets_rock_files = [
		"res://sound/announcer/lets_rock.wav",
		"res://sound/announcer/lets_rock2.wav",
		"res://sound/announcer/lets_rock3.wav"
	]
	
	var random_lets_rock = lets_rock_files[randi() % lets_rock_files.size()]
	pausa_audio_player.stream = load(random_lets_rock)
	pausa_audio_player.play()
	
	# Esperar a que termine el audio antes de reanudar
	await pausa_audio_player.finished
	
	hide_pause_menu()
	continue_pressed.emit()

func _on_quit_button_pressed() -> void:
	hide_pause_menu()
	quit_pressed.emit()
