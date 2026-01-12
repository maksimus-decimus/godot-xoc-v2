extends Node

@onready var player1 = $Player1
@onready var player2 = $Player2
@onready var ball = $Ball
@onready var hud = $CanvasLayer/HUD
@onready var camera = $Camera2D

const SPAWN_P1 = Vector2(200, 600)
const SPAWN_P2 = Vector2(1080, 600)
const SPAWN_BALL = Vector2(640, 300)

var ball_active: bool = true

func _ready() -> void:
	MusicManager.play_music(MusicManager.STAGE_MUSIC)
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
