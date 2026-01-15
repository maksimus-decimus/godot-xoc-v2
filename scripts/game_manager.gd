extends Node

@onready var player1 = $Player1
@onready var player2 = $Player2
@onready var ball = $Ball
@onready var hud = $CanvasLayer/HUD
@onready var camera = $Camera2D
@onready var showtime_sprite = $ShowTime
@onready var pause_menu = $PauseMenu

const SPAWN_P1 = Vector2(200, 600)
const SPAWN_P2 = Vector2(1080, 600)
const SPAWN_BALL = Vector2(640, 300)

var ball_active: bool = false
var players_can_move: bool = false
var is_paused: bool = false
var intro_started: bool = false

# Audio players para intro battle
var intro_battle_player: AudioStreamPlayer
var intro_battle_start_player: AudioStreamPlayer

func _ready() -> void:
	# Asegurar que el juego no esté pausado al iniciar
	get_tree().paused = false
	is_paused = false
	intro_started = false
	
	# Configurar el menú de pausa para que procese cuando esté pausado
	if pause_menu:
		pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	MusicManager.play_music(MusicManager.STAGE_MUSIC)
	
	# Ocultar ShowTime al inicio
	if showtime_sprite:
		showtime_sprite.visible = false
	
	setup_game()
	
	# Conectar señales de jugadores
	player1.player_damaged.connect(_on_player_damaged)
	player2.player_damaged.connect(_on_player_damaged)
	player1.player_defeated.connect(_on_player_defeated)
	player2.player_defeated.connect(_on_player_defeated)
	
	# Conectar señales de bola
	ball.ball_hit_player.connect(_on_ball_hit_player)
	ball.ball_speed_changed.connect(_on_ball_speed_changed)
	
	# Conectar áreas de golpe de jugadores
	player1.hit_area.body_entered.connect(_on_player1_hit_area_entered)
	player2.hit_area.body_entered.connect(_on_player2_hit_area_entered)
	
	# Conectar señales del menú de pausa
	pause_menu.continue_pressed.connect(_on_pause_continue)
	pause_menu.quit_pressed.connect(_on_pause_quit)
	
	# Desactivar movimiento de jugadores y bola
	player1.can_move = false
	player2.can_move = false
	ball.set_physics_process(false)
	
	# Iniciar secuencia de intro
	intro_started = true
	call_deferred("_start_intro")

func _input(event: InputEvent) -> void:
	# Detectar ESC para pausar/despausar
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func setup_game() -> void:
	# Posicionar jugadores
	player1.global_position = SPAWN_P1
	player1.player_id = 1
	player2.global_position = SPAWN_P2
	player2.player_id = 2
	
	# Posicionar bola
	ball.global_position = SPAWN_BALL
	
	# Actualizar HUD inicial
	hud.update_lives(1, Global.player1_lives)
	hud.update_lives(2, Global.player2_lives)
	hud.update_hp(1, player1.hp, player1.max_hp)
	hud.update_hp(2, player2.hp, player2.max_hp)
	hud.update_ball_speed(Global.INITIAL_BALL_SPEED)

func _on_player_damaged(player_id: int, damage: float) -> void:
	var player = player1 if player_id == 1 else player2
	hud.update_hp(player_id, player.hp, player.max_hp)

func _on_player_defeated(player_id: int) -> void:
	# Perder una vida
	Global.player_lost_life(player_id)
	hud.update_lives(player_id, Global.player1_lives if player_id == 1 else Global.player2_lives)
	
	# Verificar si hay ganador
	if Global.check_game_over():
		end_game()
	else:
		# Respawn
		respawn_round(player_id)

func respawn_round(defeated_player_id: int) -> void:
	# Desactivar bola
	ball_active = false
	ball.visible = false
	ball.set_physics_process(false)
	
	await get_tree().create_timer(1.0).timeout
	
	# Respawnear jugador
	var player = player1 if defeated_player_id == 1 else player2
	var spawn_pos = SPAWN_P1 if defeated_player_id == 1 else SPAWN_P2
	player.respawn(spawn_pos)
	
	# Actualizar HUD
	hud.update_hp(defeated_player_id, player.hp, player.max_hp)
	
	await get_tree().create_timer(1.0).timeout
	
	# Respawnear bola
	ball.reset_ball(SPAWN_BALL)
	ball.visible = true
	ball.set_physics_process(true)
	ball_active = true
	hud.update_ball_speed(Global.INITIAL_BALL_SPEED)

func _on_ball_hit_player(player_id: int, damage: float) -> void:
	pass  # Ya se maneja en player_damaged

func _on_ball_speed_changed(new_speed: float) -> void:
	hud.update_ball_speed(new_speed)

func _on_player1_hit_area_entered(body: Node2D) -> void:
	if body == ball and ball_active:
		ball.hit_by_player(player1.global_position, player1)

func _on_player2_hit_area_entered(body: Node2D) -> void:
	if body == ball and ball_active:
		ball.hit_by_player(player2.global_position, player2)

func screen_shake(duration: float = 2.0, intensity: float = 30.0) -> void:
	if not camera:
		print("ERROR: Camera not found!")
		return
	
	var shake_time = 0.0
	var original_offset = camera.offset
	
	while shake_time < duration:
		# Mantener intensidad constante durante todo el efecto
		var decay = 1.0 - (shake_time / duration) * 0.3
		var shake_amount = intensity * decay
		
		camera.offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		
		await get_tree().create_timer(0.02).timeout
		shake_time += 0.02
	
	camera.offset = original_offset

func end_game() -> void:
	SceneTransition.loading_screen_to_scene("res://scenes/victory_screen.tscn")

func toggle_pause() -> void:
	# Solo permitir pausar si ya han empezado a jugar (después del intro)
	if not player1.can_move or not player2.can_move:
		return
	
	# No permitir pausar si algún jugador está muerto
	if player1.is_dead or player2.is_dead:
		return
	
	if is_paused:
		# Ya está pausado, no hacer nada (el menú maneja el resume)
		return
	else:
		# Pausar el juego
		is_paused = true
		pause_menu.show_pause_menu()

func _on_pause_continue() -> void:
	is_paused = false
	get_tree().paused = false

func _on_pause_quit() -> void:
	is_paused = false
	intro_started = false
	# Asegurar que el juego se despause antes de cambiar de escena
	get_tree().paused = false
	# Volver al menú principal
	SceneTransition.loading_screen_to_scene("res://scenes/main_menu.tscn")

func _start_intro() -> void:
	await start_intro_sequence()

func start_intro_sequence() -> void:
	# Crear AudioStreamPlayer para intro_battle
	intro_battle_player = AudioStreamPlayer.new()
	add_child(intro_battle_player)
	
	# Crear AudioStreamPlayer para intro_battle_start
	intro_battle_start_player = AudioStreamPlayer.new()
	add_child(intro_battle_start_player)
	
	# Arrays con los nombres de archivos disponibles
	var intro_battle_files = [
		"res://sound/announcer/intro_battle/Intro_battle.wav",
		"res://sound/announcer/intro_battle/intro_battle2.wav",
		"res://sound/announcer/intro_battle/intro_battle_3.wav",
		"res://sound/announcer/intro_battle/intro_battle_4.wav"
	]
	
	var intro_battle_start_files = [
		"res://sound/announcer/intro_battle_start/showtime1.wav",
		"res://sound/announcer/intro_battle_start/showtime2.wav",
		"res://sound/announcer/intro_battle_start/showtime3.wav"
	]
	
	# Seleccionar archivos aleatorios
	var random_intro_battle = intro_battle_files[randi() % intro_battle_files.size()]
	var random_intro_battle_start = intro_battle_start_files[randi() % intro_battle_start_files.size()]
	
	# Reproducir primer audio (intro_battle)
	intro_battle_player.stream = load(random_intro_battle)
	intro_battle_player.play()
	
	# Esperar a que termine intro_battle
	await intro_battle_player.finished
	
	# Mostrar y reproducir ShowTime con el segundo audio
	if showtime_sprite:
		showtime_sprite.visible = true
		showtime_sprite.play()
	
	intro_battle_start_player.stream = load(random_intro_battle_start)
	intro_battle_start_player.play()
	
	# Esperar 1.5 segundos mientras se muestra ShowTime (con process_always para que funcione aunque esté pausado)
	var timer = get_tree().create_timer(1.5, true, false, true)
	await timer.timeout
	
	# Ocultar ShowTime
	if showtime_sprite:
		showtime_sprite.visible = false
		showtime_sprite.stop()
	
	# Activar movimiento de jugadores y bola
	player1.can_move = true
	player2.can_move = true
	ball.set_physics_process(true)
	ball_active = true
	
	# Limpiar los reproductores de audio
	intro_battle_player.queue_free()
	intro_battle_start_player.queue_free()
