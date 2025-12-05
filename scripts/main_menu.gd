extends Node

@onready var title_label = $CanvasLayer/CenterContainer/VBoxContainer/TitleLabel
@onready var play_button = $CanvasLayer/CenterContainer/VBoxContainer/PlayButton
@onready var quit_button = $CanvasLayer/CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	play_button.grab_focus()

func _on_play_button_pressed() -> void:
	SceneTransition.fade_to_scene("res://scenes/character_select.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
