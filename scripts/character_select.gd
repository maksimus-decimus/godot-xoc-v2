extends Node2D

# Referencias a TextureRect de fondo
@onready var char_base = $CharBase
@onready var p1_p2_fondo = $P1P2Fondo

# Referencias a íconos pequeños (seleccionables)
@onready var don_ico = $CharacterIcons/DonIco
@onready var ish_ico = $CharacterIcons/IshIco

# Referencias a imágenes grandes (preview)
@onready var don_big = $CharacterBig/DonBig
@onready var ish_big = $CharacterBig/IshBig

# Referencias a recuadros de selección
@onready var p1_selector = $Selectors/P1Selector
@onready var p2_selector = $Selectors/P2Selector

# UI
@onready var continue_button = $CanvasLayer/ContinueButton

# Botones invisibles para detectar hover/click
@onready var don_button = $CharacterIcons/DonButton
@onready var ish_button = $CharacterIcons/IshButton

# Estados de selección
var p1_character_index: int = -1  # -1 = no seleccionado, 0 = Don, 1 = Ishmael
var p2_character_index: int = -1
var current_turn: int = 1  # 1 = P1 seleccionando, 2 = P2 seleccionando
var p1_confirmed: bool = false
var p2_confirmed: bool = false

# Posiciones de los selectores según personaje
var selector_positions = {
	0: Vector2.ZERO,  # Don - se configurará en _ready
	1: Vector2.ZERO   # Ishmael - se configurará en _ready
}

func _ready() -> void:
	MusicManager.play_music(MusicManager.CHAR_SELECT_MUSIC)
	
	# Verificar que todos los nodos existen
	if not don_ico or not ish_ico or not p1_selector or not p2_selector:
		print("ERROR: Faltan nodos en la escena")
		return
	
	# Configurar posiciones de los selectores basadas en los íconos
	selector_positions[0] = don_ico.position
	selector_positions[1] = ish_ico.position
	
	# Ocultar selectores y personajes grandes al inicio
	p1_selector.visible = false
	p2_selector.visible = false
	don_big.visible = false
	ish_big.visible = false
	continue_button.visible = false
	
	# Conectar señales
	if don_button:
		don_button.pressed.connect(func(): select_character(0))
	if ish_button:
		ish_button.pressed.connect(func(): select_character(1))
	
	print("Character Select listo. Turno: P", current_turn)

func _process(_delta: float) -> void:
	# Detectar ESC para cancelar selección
	if Input.is_action_just_pressed("ui_cancel"):
		cancel_selection()
	
	# Detectar teclas de selección con teclado
	if current_turn == 1:
		if Input.is_action_just_pressed("p1_left"):
			select_character(0)  # Don
		elif Input.is_action_just_pressed("p1_right"):
			select_character(1)  # Ishmael
		elif Input.is_action_just_pressed("p1_hit") and p1_character_index >= 0:
			confirm_selection()
	elif current_turn == 2:
		if Input.is_action_just_pressed("p2_left"):
			select_character(0)  # Don
		elif Input.is_action_just_pressed("p2_right"):
			select_character(1)  # Ishmael
		elif Input.is_action_just_pressed("p2_hit") and p2_character_index >= 0:
			confirm_selection()

func select_character(character_index: int) -> void:
	if current_turn == 1:
		p1_character_index = character_index
		update_p1_visuals()
	elif current_turn == 2:
		p2_character_index = character_index
		update_p2_visuals()
	
	print("P", current_turn, " seleccionó: ", ["Don", "Ishmael"][character_index])

func confirm_selection() -> void:
	if current_turn == 1 and p1_character_index >= 0:
		p1_confirmed = true
		current_turn = 2
		print("P1 confirmó. Ahora es turno de P2")
		update_p1_visuals()  # Actualizar visuals para mostrar que está confirmado
	elif current_turn == 2 and p2_character_index >= 0:
		p2_confirmed = true
		print("P2 confirmó. Ambos listos!")
		update_p2_visuals()  # Actualizar visuals para mostrar que está confirmado
	
	# Si ambos confirmaron, mostrar botón continuar
	if p1_confirmed and p2_confirmed:
		continue_button.visible = true

func cancel_selection() -> void:
	print("Selección cancelada. Reiniciando...")
	
	# Resetear todo
	p1_character_index = -1
	p2_character_index = -1
	p1_confirmed = false
	p2_confirmed = false
	current_turn = 1
	
	# Ocultar todo
	p1_selector.visible = false
	p2_selector.visible = false
	don_big.visible = false
	ish_big.visible = false
	continue_button.visible = false

func update_p1_visuals() -> void:
	if p1_character_index < 0:
		p1_selector.visible = false
		if not p2_confirmed:
			don_big.visible = false
			ish_big.visible = false
		return
	
	# Mostrar selector P1 (azul/cyan)
	p1_selector.visible = true
	p1_selector.position = selector_positions[p1_character_index]
	
	# Cambiar color según si está confirmado
	if p1_confirmed:
		p1_selector.modulate = Color.GREEN
	else:
		p1_selector.modulate = Color.CYAN
	
	# Actualizar personaje grande
	update_big_characters()

func update_p2_visuals() -> void:
	if p2_character_index < 0:
		p2_selector.visible = false
		return
	
	# Mostrar selector P2 (rojo)
	p2_selector.visible = true
	p2_selector.position = selector_positions[p2_character_index]
	
	# Cambiar color según si está confirmado
	if p2_confirmed:
		p2_selector.modulate = Color.GREEN
	else:
		p2_selector.modulate = Color.RED
	
	# Actualizar personaje grande
	update_big_characters()

func update_big_characters() -> void:
	# Determinar qué personajes mostrar
	var show_don = (p1_character_index == 0 or p2_character_index == 0)
	var show_ish = (p1_character_index == 1 or p2_character_index == 1)
	
	don_big.visible = show_don
	ish_big.visible = show_ish
	
	# Configurar flip según quién lo tenga seleccionado
	if show_don:
		# Si P1 lo tiene, mostrar mirando a la derecha (flip)
		# Si P2 lo tiene, mostrar mirando a la izquierda (normal)
		if p1_character_index == 0:
			don_big.flip_h = true
		elif p2_character_index == 0:
			don_big.flip_h = false
	
	if show_ish:
		# Ishmael normalmente mira a la derecha
		# Si P1 lo tiene, flip (para que mire a la derecha desde su lado)
		# Si P2 lo tiene, normal (mira a la izquierda hacia P1)
		if p1_character_index == 1:
			ish_big.flip_h = true
		elif p2_character_index == 1:
			ish_big.flip_h = false

func _on_continue_button_pressed() -> void:
	if not (p1_confirmed and p2_confirmed):
		return
	
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
