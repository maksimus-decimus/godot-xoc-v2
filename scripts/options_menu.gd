extends Node

@onready var volume_slider = $CanvasLayer/CenterContainer/VBoxContainer/VolumeSlider
@onready var skip_intro_checkbox = $CanvasLayer/CenterContainer/VBoxContainer/SkipIntroCheckBox
@onready var back_button = $CanvasLayer/CenterContainer/VBoxContainer/BackButton

const CONFIG_FILE = "user://settings.cfg"

var config = ConfigFile.new()

func _ready() -> void:
	load_settings()
	back_button.grab_focus()

func load_settings() -> void:
	var err = config.load(CONFIG_FILE)
	
	if err == OK:
		# Cargar valores guardados
		var volume = config.get_value("audio", "volume", 100.0)
		var skip_intro = config.get_value("gameplay", "skip_intro", false)
		
		volume_slider.value = volume
		skip_intro_checkbox.button_pressed = skip_intro
		
		# Aplicar configuración
		apply_volume(volume)
		Global.skip_intro = skip_intro
	else:
		# Valores por defecto
		volume_slider.value = 100.0
		skip_intro_checkbox.button_pressed = false
		Global.skip_intro = false
		save_settings()

func save_settings() -> void:
	config.set_value("audio", "volume", volume_slider.value)
	config.set_value("gameplay", "skip_intro", skip_intro_checkbox.button_pressed)
	
	config.save(CONFIG_FILE)

func apply_volume(volume: float) -> void:
	# Convertir de 0-100 a dB (-80 a 0)
	var db = linear_to_db(volume / 100.0)
	if volume <= 0:
		db = -80
	# Bus 0 es Master - controla todo el audio
	AudioServer.set_bus_volume_db(0, db)

func _on_volume_slider_value_changed(value: float) -> void:
	apply_volume(value)
	save_settings()

func _on_skip_intro_toggled(toggled_on: bool) -> void:
	Global.skip_intro = toggled_on
	save_settings()

func _on_back_button_pressed() -> void:
	UISounds.play_select()
	SceneTransition.fade_to_scene("res://scenes/main_menu.tscn")
