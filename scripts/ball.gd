extends CharacterBody2D

@onready var sprite = $ColorRect
@onready var collision_shape = $CollisionShape2D
@onready var weak_sound = $WeakSound
@onready var medium_sound = $MediumSound
@onready var strong_sound = $StrongSound

var speed: float = Global.INITIAL_BALL_SPEED
var direction: Vector2 = Vector2.ZERO
var last_hit_player: CharacterBody2D = null
var owner_player_id: int = 0  # ID del jugador que tiene el "tag" de la bola (quien la golpeó último)

signal ball_hit_player(player_id: int, damage: float)
signal ball_speed_changed(new_speed: float)

func _ready() -> void:
	# Dirección inicial aleatoria
	randomize()
	var angle = randf_range(0, TAU)
	direction = Vector2(cos(angle), sin(angle)).normalized()
	velocity = direction * speed

func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		
		# Si choca con un jugador
		if collider is CharacterBody2D and collider.has_method("take_damage"):
			var player = collider
			
			# Solo hacer daño si el jugador NO es el dueño del tag
			if player.player_id != owner_player_id:
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

func calculate_damage() -> float:
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
	
	# Reproducir sonido según velocidad y aplicar efectos
	play_hit_sound_by_speed(speed, player)
	
	# Efecto visual
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.4, 1.4), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Cambiar color según velocidad
	update_color()

func update_color() -> void:
	if speed < 400:
		sprite.color = Color.WHITE
	elif speed < 800:
		sprite.color = Color.YELLOW
	elif speed < 1200:
		sprite.color = Color.ORANGE
	else:
		sprite.color = Color.RED

func play_hit_sound_by_speed(current_speed: float, player: CharacterBody2D) -> void:
	if current_speed < Global.WEAK_THRESHOLD:
		# Golpe débil
		weak_sound.play()
	elif current_speed < Global.MEDIUM_THRESHOLD:
		# Golpe medio
		medium_sound.play()
	else:
		# Golpe fuerte - efecto dramático
		strong_sound.play()
		# Llamar screen shake con misma duración que la congelación
		var game_manager = get_parent()
		if game_manager and game_manager.has_method("screen_shake"):
			game_manager.screen_shake(2.0, 30.0)
		freeze_player(player)

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
	
	# Efecto visual de "carga" en la bola
	var original_ball_color = sprite.color
	sprite.modulate = Color(1.5, 1.5, 0.5)  # Brillo amarillo/dorado
	
	# Efecto de pulsación en la bola
	var pulse_tween = create_tween()
	pulse_tween.set_loops(4)
	pulse_tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.25)
	pulse_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.25)
	
	# Descongelar después de 2 segundos
	await get_tree().create_timer(2.0).timeout
	
	if is_instance_valid(player):
		player.set_physics_process(true)
		player.is_hitting = false
		player.visual_container.modulate = original_modulate
	
	# Descongelar la bola y lanzarla con fuerza
	set_physics_process(true)
	velocity = stored_velocity
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2.ONE

func reset_ball(spawn_position: Vector2) -> void:
	global_position = spawn_position
	speed = Global.INITIAL_BALL_SPEED
	last_hit_player = null
	owner_player_id = 0  # Sin dueño al inicio
	
	# Nueva dirección aleatoria
	randomize()
	var angle = randf_range(0, TAU)
	direction = Vector2(cos(angle), sin(angle)).normalized()
	velocity = direction * speed
	
	sprite.color = Color.WHITE
	sprite.scale = Vector2.ONE
