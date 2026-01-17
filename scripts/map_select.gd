extends Node

@onready var start_button = $CanvasLayer/CenterContainer/VBoxContainer/StartButton
@onready var weather_label = $CanvasLayer/WeatherLabel

# Botones de navegación de mapas
var prev_button: Button
var next_button: Button
var map_label: Label

const MAP_NAMES = ["ARENA CLÁSICA", "MAPA 2", "MAPA 3"]

func _ready() -> void:
	MusicManager.play_music(MusicManager.CHAR_SELECT_MUSIC)
	start_button.grab_focus()
	
	# Inicializar mapa seleccionado
	if Global.selected_map < 0 or Global.selected_map >= MAP_NAMES.size():
		Global.selected_map = 0
	
	# Obtener referencias a botones de navegación si existen
	prev_button = get_node_or_null("CanvasLayer/CenterContainer/VBoxContainer/MapNavigation/PrevButton")
	next_button = get_node_or_null("CanvasLayer/CenterContainer/VBoxContainer/MapNavigation/NextButton")
	map_label = get_node_or_null("CanvasLayer/CenterContainer/VBoxContainer/MapNameLabel")
	
	# Conectar señales si los botones existen
	if prev_button:
		prev_button.pressed.connect(_on_prev_button_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)
	
	# Actualizar UI
	update_map_display()
	update_weather_display()

func update_map_display() -> void:
	if map_label:
		map_label.text = MAP_NAMES[Global.selected_map]

func update_weather_display() -> void:
	var weather_text = "Clima: " + WeatherAPI.current_weather_type
	weather_label.text = weather_text

func _on_prev_button_pressed() -> void:
	UISounds.play_select()
	Global.selected_map -= 1
	if Global.selected_map < 0:
		Global.selected_map = MAP_NAMES.size() - 1
	update_map_display()

func _on_next_button_pressed() -> void:
	UISounds.play_select()
	Global.selected_map += 1
	if Global.selected_map >= MAP_NAMES.size():
		Global.selected_map = 0
	update_map_display()

func _on_start_button_pressed() -> void:
	UISounds.play_select()
	SceneTransition.loading_screen_to_scene("res://scenes/game.tscn")
