extends Node

@onready var video_player = $CanvasLayer/VideoStreamPlayer

func _ready() -> void:
	# Conectar señal de fin de video
	video_player.finished.connect(_on_video_finished)
	video_player.play()

func _input(event: InputEvent) -> void:
	# Permitir saltar intro con cualquier tecla
	if event.is_pressed():
		skip_intro()

func _on_video_finished() -> void:
	# Ir al menú principal cuando termine el video
	SceneTransition.loading_screen_to_scene("res://scenes/main_menu.tscn")

func skip_intro() -> void:
	# Saltar al menú principal
	SceneTransition.loading_screen_to_scene("res://scenes/main_menu.tscn")
