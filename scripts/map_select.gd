extends Node

@onready var start_button = $CanvasLayer/CenterContainer/VBoxContainer/StartButton
@onready var weather_label = $CanvasLayer/WeatherLabel

func _ready() -> void:
	MusicManager.play_music(MusicManager.CHAR_SELECT_MUSIC)
	start_button.grab_focus()
	Global.selected_map = 0
	
	# Mostrar clima actual
	update_weather_display()

func update_weather_display() -> void:
	var weather_text = "Clima: " + WeatherAPI.current_weather_type
	weather_label.text = weather_text

func _on_start_button_pressed() -> void:
	UISounds.play_select()
	SceneTransition.loading_screen_to_scene("res://scenes/game.tscn")
