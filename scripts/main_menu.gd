extends Node

@onready var play_choice = $CanvasLayer/PlayChoice
@onready var quit_choice = $CanvasLayer/QuitChoice
@onready var profile_choice = $CanvasLayer/ProfileChoice
@onready var play_button = $CanvasLayer/PlayChoice/PlayButton
@onready var quit_button = $CanvasLayer/QuitChoice/QuitButton
@onready var profile_button = $CanvasLayer/ProfileChoice/ProfileButton
@onready var profile_name_label = $CanvasLayer/ProfileNameLabel

# Posiciones base y desplazamientos
var play_base_x: float = 120.0
var quit_base_x: float = 120.0
var profile_base_x: float = 120.0
var offset_selected: float = 30.0  # Desplazamiento a la derecha cuando está seleccionado
var offset_unselected: float = -15.0  # Desplazamiento a la izquierda cuando NO está seleccionado

var current_focused_button = null
var all_buttons = []  # Array con todos los botones
var all_choices = []  # Array con todos los sprites choice

func _ready() -> void:
	MusicManager.play_music(MusicManager.TITLE_MUSIC)
	
	# Validar API del tiempo
	WeatherAPI.api_validation_result.connect(_on_api_validation)
	WeatherAPI.fetch_weather()
	
	# Inicializar arrays
	all_buttons = [play_button, quit_button, profile_button]
	all_choices = [play_choice, quit_choice, profile_choice]
	
	# Conectar señales de focus y hover
	if play_button:
		play_button.focus_entered.connect(_on_play_focus_entered)
		play_button.mouse_entered.connect(_on_play_mouse_entered)
		play_button.grab_focus()
		current_focused_button = play_button
		# Inicializar posición seleccionada
		play_choice.position.x = play_base_x + offset_selected
	
	if quit_button:
		quit_button.focus_entered.connect(_on_quit_focus_entered)
		quit_button.mouse_entered.connect(_on_quit_mouse_entered)
		# Inicializar posición no seleccionada
		quit_choice.position.x = quit_base_x + offset_unselected
	
	if profile_button:
		profile_button.focus_entered.connect(_on_profile_focus_entered)
		profile_button.mouse_entered.connect(_on_profile_mouse_entered)
		# Inicializar posición no seleccionada
		profile_choice.position.x = profile_base_x + offset_unselected
	
	# Actualizar nombre del perfil
	update_profile_display()
	
	# Validar API del tiempo
	WeatherAPI.api_validation_result.connect(_on_api_validation)
	WeatherAPI.fetch_weather()

func _on_api_validation(is_valid: bool, message: String) -> void:
	print(message)

func _input(event: InputEvent) -> void:
	# Detectar W/S para navegación
	if event.is_action_pressed("p1_up") or event.is_action_pressed("p2_up"):
		if current_focused_button == profile_button:
			UISounds.play_slide()
			play_button.grab_focus()
		elif current_focused_button == quit_button:
			UISounds.play_slide()
			profile_button.grab_focus()
	elif event.is_action_pressed("p1_down") or event.is_action_pressed("p2_down"):
		if current_focused_button == play_button:
			UISounds.play_slide()
			profile_button.grab_focus()
		elif current_focused_button == profile_button:
			UISounds.play_slide()
			quit_button.grab_focus()

func _on_play_focus_entered() -> void:
	animate_selection_multi(play_choice)
	current_focused_button = play_button

func _on_play_mouse_entered() -> void:
	UISounds.play_slide()
	play_button.grab_focus()

func _on_quit_focus_entered() -> void:
	animate_selection_multi(quit_choice)
	current_focused_button = quit_button

func _on_quit_mouse_entered() -> void:
	UISounds.play_slide()
	quit_button.grab_focus()

func _on_profile_focus_entered() -> void:
	animate_selection_multi(profile_choice)
	current_focused_button = profile_button

func _on_profile_mouse_entered() -> void:
	UISounds.play_slide()
	profile_button.grab_focus()

func animate_selection_multi(selected_choice: Sprite2D) -> void:
	# Animar todos los botones
	for i in range(all_choices.size()):
		var choice = all_choices[i]
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		
		# Obtener posición base según el índice
		var base_x = play_base_x if choice == play_choice else (quit_base_x if choice == quit_choice else profile_base_x)
		
		if choice == selected_choice:
			# Mover a la derecha (seleccionado)
			tween.tween_property(choice, "position:x", base_x + offset_selected, 0.3)
		else:
			# Mover a la izquierda (no seleccionado)
			tween.tween_property(choice, "position:x", base_x + offset_unselected, 0.3)

func animate_selection(selected_choice: Sprite2D, other_choice: Sprite2D) -> void:
	# Animar el botón seleccionado hacia la derecha
	var tween_selected = create_tween()
	tween_selected.set_ease(Tween.EASE_OUT)
	tween_selected.set_trans(Tween.TRANS_CUBIC)
	
	var base_x = play_base_x if selected_choice == play_choice else quit_base_x
	tween_selected.tween_property(selected_choice, "position:x", base_x + offset_selected, 0.3)
	
	# Animar el otro botón hacia la izquierda
	var tween_other = create_tween()
	tween_other.set_ease(Tween.EASE_OUT)
	tween_other.set_trans(Tween.TRANS_CUBIC)
	
	var other_base_x = play_base_x if other_choice == play_choice else quit_base_x
	tween_other.tween_property(other_choice, "position:x", other_base_x + offset_unselected, 0.3)

func update_profile_display() -> void:
	if UserProfile.current_profile_name.is_empty():
		profile_name_label.text = "Sin perfil"
		profile_name_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
	else:
		profile_name_label.text = "Jugando como: %s" % UserProfile.current_profile_name
		profile_name_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_play_button_pressed() -> void:
	UISounds.play_select()
	SceneTransition.loading_screen_to_scene("res://scenes/character_select_new.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_profile_button_pressed() -> void:
	UISounds.play_select()
	SceneTransition.loading_screen_to_scene("res://scenes/profile_select.tscn")
