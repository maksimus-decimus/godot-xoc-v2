extends Node

@onready var title_label = $CanvasLayer/TitleLabel
@onready var play_button = $CanvasLayer/PlayButton
@onready var quit_button = $CanvasLayer/QuitButton
@onready var profile_button = $CanvasLayer/ProfileButton
@onready var profile_name_label = $CanvasLayer/ProfileNameLabel

func _ready() -> void:
	MusicManager.play_music(MusicManager.TITLE_MUSIC)
	play_button.grab_focus()
	profile_button.pressed.connect(_on_profile_button_pressed)
	
	# Actualizar nombre del perfil
	update_profile_display()

func update_profile_display() -> void:
	if UserProfile.current_profile_name.is_empty():
		profile_name_label.text = "Sin perfil"
		profile_name_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
	else:
		profile_name_label.text = "Jugando como: %s" % UserProfile.current_profile_name
		profile_name_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_play_button_pressed() -> void:
	SceneTransition.loading_screen_to_scene("res://scenes/character_select_new.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_profile_button_pressed() -> void:
	SceneTransition.loading_screen_to_scene("res://scenes/profile_select.tscn")
