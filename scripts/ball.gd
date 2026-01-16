extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var hit_sprite = $HitSprite
@onready var collision_shape = $CollisionShape2D

# Arrays de variantes de sonidos
var weak_sounds: Array[AudioStream] = []
var medium_sounds: Array[AudioStream] = []
var strong_sounds: Array[AudioStream] = []
var wall_bounce_sounds: Array[AudioStream] = []

@export var ball_scale: float = 1.0  # Escala de la pelota (ajustable desde Inspector)
@export var rotation_speed: float = 3.0  # Velocidad de rotación

var speed: float = Global.INITIAL_BALL_SPEED
var direction: Vector2 = Vector2.ZERO
var last_hit_player: CharacterBody2D = null
var owner_player_id: int = 0  # ID del jugador que tiene el "tag" de la bola (quien la golpeó último)
var is_ultimate_shot: bool = false  # Si la bola fue lanzada por una ultimate

signal ball_hit_player(player_id: int, damage: float)
signal ball_speed_changed(new_speed: float)

func _ready() -> void:
	# Cargar variantes de sonidos de golpe
	weak_sounds.clear()
	weak_sounds.append(load("res://sound/sfx/golpe/weak_hit.wav"))
	weak_sounds.append(load("res://sound/sfx/golpe/weak_smash.wav"))
	
	medium_sounds.clear()
	medium_sounds.append(load("res://sound/sfx/golpe/medium_hit.wav"))
	medium_sounds.append(load("res://sound/sfx/golpe/medium_smash.wav"))
	
	strong_sounds.clear()
	strong_sounds.append(load("res://sound/sfx/golpe/strong_hit.wav"))
	strong_sounds.append(load("res://sound/sfx/golpe/strong_smash.wav"))
	
	wall_bounce_sounds.clear()
	wall_bounce_sounds.append(load("res://sound/sfx/ball/wall_bounce.wav"))
	wall_bounce_sounds.append(load("res://sound/sfx/ball/wall_bounce_fast.wav"))
	
	# Dirección inicial aleatoria
	randomize()
	var angle = randf_range(0, TAU)
	direction = Vector2(cos(angle), sin(angle)).normalized()
	velocity = direction * speed
	# Aplicar escala
	sprite.scale = Vector2(ball_scale, ball_scale)
	hit_sprite.scale = Vector2(ball_scale, ball_scale)
	hit_sprite.visible = false
	# Iniciar en estado neutral
	update_tag_color()

func _physics_process(delta: float) -> void:
	# Rotar la pelota continuamente
	sprite.rotation += rotation_speed * delta
	
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		
		# Si choca con un jugador
		if collider is CharacterBody2D and collider.has_method("take_damage"):
			var player = collider
			
			# Solo hacer daño si:
			# 1. La pelota NO está en estado neutral (owner_player_id != 0)
			# 2. El jugador NO es el dueño del tag
			if owner_player_id != 0 and player.player_id != owner_player_id:
				var damage = calculate_damage()
				var knockback_dir = (player.global_position - global_position).normalized()
				
				ball_hit_player.emit(player.player_id, damage)
				player.take_damage(damage, knockback_dir)
			
			# Rebotar siempre, incluso si no hace daño
			velocity = velocity.bounce(collision.get_normal())
			direction = velocity.normalized()
		else:
			# Rebotar en paredes
			velocity = velocity.bounce(collision.get_normal())
			direction = velocity.normalized()
			
			# Reproducir sonido de rebote en pared
			if wall_bounce_sounds.size() > 0:
				var sound = wall_bounce_sounds.pick_random()
				var audio = AudioStreamPlayer.new()
				audio.stream = sound
				audio.bus = "SFX"
				add_child(audio)
				audio.play()
				# Eliminar el reproductor después de que termine
				audio.finished.connect(func(): audio.queue_free())

func calculate_damage() -> float:
	# DEBUG: One-hit kill mode
	if Global.debug_one_hit_kill:
		return 999.0
	
	# Si es un disparo de ultimate, hacer 999 de daño
	if is_ultimate_shot:
		is_ultimate_shot = false  # Resetear después del primer golpe
		return 999.0
	
	# El daño escala con la velocidad
	var speed_ratio = speed / Global.INITIAL_BALL_SPEED
	return Global.BASE_DAMAGE * speed_ratio

func hit_by_player(player_position: Vector2, player: CharacterBody2D) -> void:
	# Incrementar velocidad
	speed += Global.BALL_SPEED_INCREMENT
	speed = min(speed, Global.MAX_BALL_SPEED)
	
	# Cambiar dirección hacia el lado opuesto del jugador
	direction = (global_position - player_position).normalized()
	velocity = direction * speed
	
	last_hit_player = player
	# Actualizar el tag: ahora este jugador es el dueño de la bola
	owner_player_id = player.player_id
	ball_speed_changed.emit(speed)
	
	# Cambiar color según el dueño del tag PRIMERO
	update_tag_color()
	
	# Reproducir sonido según velocidad y aplicar efectos
	play_hit_sound_by_speed(speed, player)
	
	# Efecto visual - mantener ball_scale
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(ball_scale * 1.4, ball_scale * 1.4), 0.1)
	tween.tween_property(sprite, "scale", Vector2(ball_scale, ball_scale), 0.1)

func update_tag_color() -> void:
	# Color según quién tiene el tag (usa modulate para sprites)
	if owner_player_id == 0:
		# Neutral - blanco
		sprite.modulate = Color.WHITE
	elif owner_player_id == 1:
		# Player 1 - azul
		sprite.modulate = Color.DODGER_BLUE
	elif owner_player_id == 2:
		# Player 2 - rojo
		sprite.modulate = Color.RED

func update_color() -> void:
	if speed < 400:
		sprite.modulate = Color.WHITE
	elif speed < 800:
		sprite.modulate = Color.YELLOW
	elif speed < 1200:
		sprite.modulate = Color.ORANGE
	else:
		sprite.modulate = Color.RED

func play_hit_sound_by_speed(current_speed: float, player: CharacterBody2D) -> void:
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	if current_speed < Global.WEAK_THRESHOLD:
		# Golpe débil - elegir variante aleatoria
		var random_weak = weak_sounds[randi() % weak_sounds.size()]
		audio_player.stream = random_weak
		audio_player.play()
	elif current_speed < Global.MEDIUM_THRESHOLD:
		# Golpe medio - elegir variante aleatoria
		var random_medium = medium_sounds[randi() % medium_sounds.size()]
		audio_player.stream = random_medium
		audio_player.play()
	else:
		# Golpe fuerte - elegir variante aleatoria
		var random_strong = strong_sounds[randi() % strong_sounds.size()]
		audio_player.stream = random_strong
		audio_player.play()
		# Llamar screen shake con duración reducida a la mitad (1.0s)
		var game_manager = get_parent()
		if game_manager and game_manager.has_method("screen_shake"):
			game_manager.screen_shake(1.0, 30.0)
		freeze_player(player)
		# Mostrar sprite de golpe orientado según dirección
		show_hit_effect()

func show_hit_effect() -> void:
	# Mostrar sprite de golpe orientado según la dirección
	hit_sprite.visible = true
	hit_sprite.rotation = direction.angle()
	# Ocultar después de un breve momento
	await get_tree().create_timer(0.15).timeout
	hit_sprite.visible = false

func freeze_player(player: CharacterBody2D) -> void:
	# Congelar al jugador que golpeó fuerte
	player.set_physics_process(false)
	player.is_hitting = true  # Prevenir que golpee durante congelación
	
	# Congelar la bola también
	set_physics_process(false)
	var stored_velocity = velocity
	velocity = Vector2.ZERO
	
	# Efecto visual de congelación en jugador
	var original_modulate = player.visual_container.modulate
	player.visual_container.modulate = Color(0.5, 0.5, 1.0)  # Tinte azul
	
	# Efecto visual de "carga" en la bola - combinar con color del tag
	var original_ball_color = sprite.modulate
	# Aplicar brillo manteniendo el tinte del tag
	var brightened_color = original_ball_color * 1.5
	brightened_color.a = 1.0  # Mantener alpha
	sprite.modulate = brightened_color
	
	# Efecto de pulsación en la bola - mantener ball_scale
	var pulse_tween = create_tween()
	pulse_tween.set_loops(2)  # Mitad de 4 loops
	pulse_tween.tween_property(sprite, "scale", Vector2(ball_scale * 1.3, ball_scale * 1.3), 0.125)  # 0.25 / 2
	pulse_tween.tween_property(sprite, "scale", Vector2(ball_scale, ball_scale), 0.125)
	
	# Descongelar después de 1.0 segundo (mitad de 2.0)
	await get_tree().create_timer(1.0).timeout
	
	if is_instance_valid(player):
		player.set_physics_process(true)
		player.is_hitting = false
		player.visual_container.modulate = original_modulate
	
	# Descongelar la bola y restaurar su color original del tag
	set_physics_process(true)
	velocity = stored_velocity
	sprite.modulate = original_ball_color
	sprite.scale = Vector2(ball_scale, ball_scale)

func reset_ball(spawn_position: Vector2) -> void:
	global_position = spawn_position
	speed = Global.INITIAL_BALL_SPEED
	last_hit_player = null
	owner_player_id = 0  # Volver a estado neutral
	
	# Nueva dirección aleatoria
	randomize()
	var angle = randf_range(0, TAU)
	direction = Vector2(cos(angle), sin(angle)).normalized()
	velocity = direction * speed
	
	# Volver a color neutral (blanco)
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2(ball_scale, ball_scale)
	hit_sprite.visible = false
