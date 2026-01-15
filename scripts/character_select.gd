extends Node2D

# Referencias a TextureRect de fondo
@onready var char_base = $CharBase
@onready var p1_p2_fondo = $P1P2Fondo

# Referencias a íconos pequeños (seleccionables)
@onready var don_ico = $CharacterIcons/DonIco
@onready var ish_ico = $CharacterIcons/IshIco

# Referencias a imágenes grandes (preview) - Separadas por lado
@onready var character_big_l = $CharacterBigL  # Lado izquierdo (P1)
@onready var character_big_r = $CharacterBigR  # Lado derecho (P2)

# Referencias a recuadros de selección
@onready var p1_selector = $Selectors/P1Selector
@onready var p2_selector = $Selectors/P2Selector

# UI
@onready var continue_button = $CanvasLayer/ContinueButton

# Botones invisibles para detectar hover/click
@onready var don_button = $CharacterIcons/DonButton
@onready var ish_button = $CharacterIcons/IshButton

# Estados de selección
var p1_character_index: int = 0  # Empieza en Don
var p2_character_index: int = 0  # Empieza en Don
var p1_confirmed: bool = false
var p2_confirmed: bool = false

# Posiciones exactas de los selectores (ajusta estos valores según tus íconos)
var selector_positions = [
	Vector2(0,0),  # Don - posición del selector sobre Don
	Vector2(255, 0)   # Ishmael - posición del selector sobre Ishmael
]

func _ready() -> void:
	MusicManager.play_music(MusicManager.CHAR_SELECT_MUSIC)
	
	# Ocultar personajes grandes y botón continuar al inicio
	if character_big_l:
		for child in character_big_l.get_children():
			child.visible = false
	if character_big_r:
		for child in character_big_r.get_children():
			child.visible = false
	
	if continue_button:
		continue_button.visible = false
	
	# Mostrar selector P1 en la primera posición (Don)
	if p1_selector:
		p1_selector.visible = true
		p1_selector.position = selector_positions[0]
	
	# Ocultar selector P2 hasta que P1 confirme
	if p2_selector:
		p2_selector.visible = false
	
	# Conectar señales
	if continue_button:
		continue_button.pressed.connect(_on_continue_button_pressed)
	if don_button:
		don_button.pressed.connect(func(): select_character_by_click(0))
	if ish_button:
		ish_button.pressed.connect(func(): select_character_by_click(1))
	
	# Actualizar visual inicial
	update_p1_visuals()
	
	print("Character Select listo. P1 puede navegar con A/D")

func _process(_delta: float) -> void:
	# Detectar ESC para cancelar selección
	if Input.is_action_just_pressed("ui_cancel"):
		cancel_selection()
	
	# Navegación y confirmación para P1
	if not p1_confirmed:
		if Input.is_action_just_pressed("p1_left"):
			UISounds.play_slide()
			p1_character_index = 0  # Don
			update_p1_visuals()
		elif Input.is_action_just_pressed("p1_right"):
			UISounds.play_slide()
			p1_character_index = 1  # Ishmael
			update_p1_visuals()
		elif Input.is_action_just_pressed("p1_hit"):
			confirm_p1()
	
	# Navegación y confirmación para P2 (solo si P1 ya confirmó)
	if p1_confirmed and not p2_confirmed:
		if Input.is_action_just_pressed("p2_left"):
			UISounds.play_slide()
			p2_character_index = 0  # Don
			update_p2_visuals()
		elif Input.is_action_just_pressed("p2_right"):
			UISounds.play_slide()
			p2_character_index = 1  # Ishmael
			update_p2_visuals()
		elif Input.is_action_just_pressed("p2_hit"):
			confirm_p2()

func select_character_by_click(character_index: int) -> void:
	UISounds.play_slide()
	if not p1_confirmed:
		p1_character_index = character_index
		update_p1_visuals()
	elif not p2_confirmed:
		p2_character_index = character_index
		update_p2_visuals()

func confirm_p1() -> void:
	UISounds.play_select()
	p1_confirmed = true
	print("P1 confirmó: ", ["Don", "Ishmael"][p1_character_index])
	
	# Cambiar color del selector P1 a verde (confirmado)
	if p1_selector:
		p1_selector.modulate = Color(0.5, 1, 0.5)  # Verde claro
	
	# Mostrar selector P2 en la primera posición
	if p2_selector:
		p2_selector.visible = true
		p2_selector.position = selector_positions[0]
	
	p2_character_index = 0
	update_p2_visuals()
	
	print("Ahora es turno de P2. Navega con ←/→")

func confirm_p2() -> void:
	UISounds.play_select()
	p2_confirmed = true
	print("P2 confirmó: ", ["Don", "Ishmael"][p2_character_index])
	
	# Cambiar color del selector P2 a verde (confirmado)
	if p2_selector:
		p2_selector.modulate = Color(1, 0.5, 0.5)  # Rojo claro/rosa
	
	# Mostrar botón continuar
	if continue_button:
		continue_button.visible = true

func cancel_selection() -> void:
	UISounds.play_cancel()
	print("Selección cancelada. Reiniciando...")
	
	# Resetear todo
	p1_character_index = 0
	p2_character_index = 0
	p1_confirmed = false
	p2_confirmed = false
	
	# Resetear selectores
	if p1_selector:
		p1_selector.visible = true
		p1_selector.position = selector_positions[0]
		p1_selector.modulate = Color.WHITE
	
	if p2_selector:
		p2_selector.visible = false
		p2_selector.modulate = Color.WHITE
	
	# Ocultar personajes grandes
	if character_big_l:
		for child in character_big_l.get_children():
			child.visible = false
	if character_big_r:
		for child in character_big_r.get_children():
			child.visible = false
	
	# Ocultar botón continuar
	if continue_button:
		continue_button.visible = false
	
	# Actualizar visual
	update_p1_visuals()

func update_p1_visuals() -> void:
	# Mover selector P1 a la posición del personaje seleccionado
	if p1_selector:
		p1_selector.position = selector_positions[p1_character_index]
	
	# Actualizar personaje grande izquierdo
	update_big_character_left(p1_character_index)

func update_p2_visuals() -> void:
	# Mover selector P2 a la posición del personaje seleccionado
	if p2_selector:
		p2_selector.position = selector_positions[p2_character_index]
	
	# Actualizar personaje grande derecho
	update_big_character_right(p2_character_index)

func update_big_character_left(character_index: int) -> void:
	if not character_big_l:
		return
	
	# Ocultar todos los hijos primero
	for child in character_big_l.get_children():
		child.visible = false
	
	# Mostrar solo el personaje seleccionado
	if character_index == 0 and character_big_l.has_node("DonBig"):
		character_big_l.get_node("DonBig").visible = true
	elif character_index == 1 and character_big_l.has_node("IshBig"):
		character_big_l.get_node("IshBig").visible = true

func update_big_character_right(character_index: int) -> void:
	if not character_big_r:
		return
	
	# Ocultar todos los hijos primero
	for child in character_big_r.get_children():
		child.visible = false
	
	# Mostrar solo el personaje seleccionado
	if character_index == 0 and character_big_r.has_node("DonBig"):
		character_big_r.get_node("DonBig").visible = true
	elif character_index == 1 and character_big_r.has_node("IshBig"):
		character_big_r.get_node("IshBig").visible = true

func _on_continue_button_pressed() -> void:
	if not (p1_confirmed and p2_confirmed):
		return
	
	UISounds.play_select()
	
	# Guardar selecciones en Global
	Global.player1_character = p1_character_index
	Global.player2_character = p2_character_index
	
	# Guardar perfil del jugador 1
	UserProfile.current_profile["main_character"] = p1_character_index
	UserProfile.save_profile()
	UserProfile.save_last_profile()
	
	print("P1: ", ["Don", "Ishmael"][p1_character_index])
	print("P2: ", ["Don", "Ishmael"][p2_character_index])
	
	# Cargar escena de selección de mapa
	SceneTransition.loading_screen_to_scene("res://scenes/map_select.tscn")
