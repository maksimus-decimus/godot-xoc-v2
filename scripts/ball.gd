extends CharacterBody2D

# Referencia al sprite visual (puede ser AnimatedSprite2D o Sprite2D)
var sprite: Node2D = null
var hit_sprite: Node2D = null
@onready var collision_shape = $CollisionShape2D

# Nodo pivote para efectos visuales (Squash & Stretch)
var visual_pivot: Node2D = null
var ghost_timer: float = 0.0
const GHOST_INTERVAL: float = 0.05

# Nodo de shockwave (se creará dinámicamente)
var shockwave_node: ColorRect = null
var shockwave_material: ShaderMaterial = null

# Hit Effects Players
var p1_hit_effect: AnimatedSprite2D = null
var p2_hit_effect: AnimatedSprite2D = null

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
	# Intentar encontrar el sprite correcto dinámicamente
	if has_node("bola_animada"):
		sprite = get_node("bola_animada")
	elif has_node("Sprite2D"):
		sprite = get_node("Sprite2D")
	else:
		# Buscar cualquier hijo que sea AnimatedSprite2D
		for child in get_children():
			if child is AnimatedSprite2D:
				sprite = child
				break
				
	if not sprite:
		printerr("ERROR: No se encontró ningún nodo de sprite (bola_animada o Sprite2D) en la pelota.")
		return
		
	# Intentar encontrar HitSprite de forma segura
	if has_node("HitSprite"):
		hit_sprite = get_node("HitSprite")
	else:
		# Fallback: buscar por nombre en hijos
		hit_sprite = find_child("HitSprite", true, false)

	# Buscar efectos de golpe de jugadores (con búsqueda recursiva por seguridad)
	# Player 1 effect
	if has_node("p1 light hit"):
		p1_hit_effect = get_node("p1 light hit")
	else:
		p1_hit_effect = find_child("p1 light hit", true, false)
		
	if p1_hit_effect:
		print("DEBUG: Found p1 light hit node")
		p1_hit_effect.visible = false
		p1_hit_effect.z_index = 10 # Asegurar que se vea encima
		if p1_hit_effect is AnimatedSprite2D:
			if not p1_hit_effect.animation_finished.is_connected(func(): p1_hit_effect.visible = false):
				p1_hit_effect.animation_finished.connect(func(): p1_hit_effect.visible = false)
	else:
		print("DEBUG: Could NOT find 'p1 light hit' node")
	
	# Player 2 effect
	if has_node("p2 light hit"):
		p2_hit_effect = get_node("p2 light hit")
	else:
		p2_hit_effect = find_child("p2 light hit", true, false)
		
	if p2_hit_effect:
		print("DEBUG: Found p2 light hit node")
		p2_hit_effect.visible = false
		p2_hit_effect.z_index = 10 # Asegurar que se vea encima
		if p2_hit_effect is AnimatedSprite2D:
			if not p2_hit_effect.animation_finished.is_connected(func(): p2_hit_effect.visible = false):
				p2_hit_effect.animation_finished.connect(func(): p2_hit_effect.visible = false)
	else:
		print("DEBUG: Could NOT find 'p2 light hit' node")

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
	
	# SETUP VISUAL PIVOT
	# Creamos un nuevo nodo Node2D que será padre del sprite
	# Esto permite rotar el pivote hacia la dirección del movimiento (para estirar)
	# MIENTRAS rotamos el sprite independientemente (para girar)
	visual_pivot = Node2D.new()
	visual_pivot.name = "VisualPivot"
	add_child(visual_pivot)
	
	# Mover sprite y hit_sprite dentro del pivote
	remove_child(sprite)
	visual_pivot.add_child(sprite)
	
	if hit_sprite:
		remove_child(hit_sprite)
		visual_pivot.add_child(hit_sprite)
		
	# Mover también los efectos de golpe al pivote para que sigan la rotación visual si se desea
	# O mantenerlos globales. Si los unimos al pivote, rotarán con el "spin" de la bola si no tenemos cuidado,
	# pero el visual_pivot rota hacia la dirección del movimiento, lo cual es bueno.
	# El sprite dentro rota por su cuenta.
	# Vamos a moverlos al visual_pivot para consistencia
	if p1_hit_effect:
		p1_hit_effect.get_parent().remove_child(p1_hit_effect)
		visual_pivot.add_child(p1_hit_effect)
		
	if p2_hit_effect:
		p2_hit_effect.get_parent().remove_child(p2_hit_effect)
		visual_pivot.add_child(p2_hit_effect)
	
	# Reproducir animación si es un AnimatedSprite2D
	if sprite is AnimatedSprite2D:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("default"):
			sprite.play("default")
	
	# SETUP ESCALA: Usar la escala del editor como base
	# Capturamos la escala actual del sprite para usarla como ball_scale
	ball_scale = sprite.scale.x
	
	if hit_sprite:
		hit_sprite.scale = Vector2(ball_scale, ball_scale)
		hit_sprite.visible = false
		
	# Iniciar en estado neutral
	update_tag_color()
	
	# Inicializar el nodo de shockwave
	setup_shockwave()

func _process(delta: float) -> void:
	if not sprite or not visual_pivot:
		return

	# Rotación del sprite (Spin)
	sprite.rotation += rotation_speed * delta
	
	# Squash & Stretch (Smear Effect)
	if velocity.length() > 10:
		# Orientar el pivote hacia la dirección del movimiento
		visual_pivot.rotation = velocity.angle()
		
		# Calcular factor de estiramiento basado en la velocidad
		# Rango: 1.0 (reposo) a 2.0 (velocidad máx)
		var stretch_factor = 1.0 + (speed / Global.MAX_BALL_SPEED) * 0.8
		
		# Aplicar escala al pivote:
		# X se estira (largo), Y se aplasta (ancho) para conservar volumen
		visual_pivot.scale.x = stretch_factor
		visual_pivot.scale.y = 1.0 / sqrt(stretch_factor)
	
	# Trail Effect (Ghosting)
	if speed > Global.MEDIUM_THRESHOLD:
		ghost_timer -= delta
		if ghost_timer <= 0:
			spawn_ghost_trail()
			ghost_timer = GHOST_INTERVAL

func _physics_process(delta: float) -> void:
	# NOTA: La rotación visual del sprite ahora está en _process
	
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

func spawn_ghost_trail() -> void:
	if not sprite:
		return

	# Obtener textura del frame actual
	var current_texture = null
	
	if sprite is AnimatedSprite2D and sprite.sprite_frames:
		# Es un AnimatedSprite2D
		current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	elif sprite is Sprite2D:
		# Es un Sprite2D normal
		current_texture = sprite.texture
	
	if not current_texture:
		return # No pudimos obtener textura, abortar
		
	var ghost = Sprite2D.new()
	ghost.texture = current_texture
	ghost.scale = sprite.scale # Escala base del sprite
	ghost.global_position = global_position
	ghost.rotation = sprite.global_rotation # Rotación real del sprite (spin)
	ghost.modulate = sprite.modulate
	ghost.z_index = -1 # Detrás de todo
	
	# Aplicar también la deformación del pivote al ghost
	# Para simular esto simplemente escalamos el ghost en la dirección del movimiento
	# Pero como el ghost es hijo directo del root (o world), necesitamos aplicar la transformación manualmente
	
	# Truco: Añadimos el ghost a la escena principal, no a la bola
	get_parent().add_child(ghost)
	
	# Aplicar la misma deformación que tiene el pivote actualmente
	var transform_matrix = visual_pivot.global_transform
	# Extraer la escala y rotación del pivote para aplicarla visualmente al ghost
	ghost.global_position = global_position
	ghost.rotation = visual_pivot.global_rotation
	ghost.scale.x = sprite.scale.x * visual_pivot.scale.x
	ghost.scale.y = sprite.scale.y * visual_pivot.scale.y
	
	# Tween para desvanecer
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_property(ghost, "scale", ghost.scale * 0.5, 0.3)
	tween.chain().tween_callback(func(): ghost.queue_free())

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
		# Freeze corto para golpe medio (0.15s)
		freeze_player(player, 0.15)
	else:
		# Golpe fuerte - elegir variante aleatoria
		var random_strong = strong_sounds[randi() % strong_sounds.size()]
		audio_player.stream = random_strong
		audio_player.play()
		# Llamar screen shake con duración reducida a la mitad (1.0s)
		var game_manager = get_parent()
		if game_manager and game_manager.has_method("screen_shake"):
			game_manager.screen_shake(1.0, 30.0)
		# Freeze largo para golpe fuerte (1.15s - un segundo más que el medio)
		freeze_player(player, 1.15)
		# Mostrar sprite de golpe orientado según dirección
		show_hit_effect()
		# ¡ACTIVAR EFECTO DE SHOCKWAVE!
		play_shockwave_effect()

	# Reproducir efecto específico del jugador si existe
	play_player_specific_hit_effect(player)

func show_hit_effect() -> void:
	if not hit_sprite:
		return
	# Mostrar sprite de golpe orientado según la dirección
	hit_sprite.visible = true
	hit_sprite.rotation = direction.angle()
	# Ocultar después de un breve momento
	await get_tree().create_timer(0.15).timeout
	if hit_sprite:
		hit_sprite.visible = false

var current_freeze_generation: int = 0
var currently_frozen_player: CharacterBody2D = null

func freeze_player(player: CharacterBody2D, duration: float) -> void:
	# 1. Limpiar freeze anterior si existe y es válido
	if currently_frozen_player and is_instance_valid(currently_frozen_player):
		_unfreeze_immediate(currently_frozen_player)
	
	# 2. Configurar nuevo freeze
	current_freeze_generation += 1
	var my_gen = current_freeze_generation
	
	currently_frozen_player = player
	
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
	var loops = int(duration / 0.25)
	if loops < 1: loops = 1
	pulse_tween.set_loops(loops)
	pulse_tween.tween_property(sprite, "scale", Vector2(ball_scale * 1.3, ball_scale * 1.3), 0.125)
	pulse_tween.tween_property(sprite, "scale", Vector2(ball_scale, ball_scale), 0.125)
	
	# Descongelar después de la duración especificada
	await get_tree().create_timer(duration).timeout
	
	# 3. Verificar si seguimos siendo el freeze activo
	if current_freeze_generation == my_gen:
		_unfreeze_immediate(player)
		currently_frozen_player = null
		
		# Restaurar estado de la bola (solo si somos el freeze activo)
		set_physics_process(true)
		velocity = stored_velocity
		sprite.modulate = original_ball_color
		sprite.scale = Vector2(ball_scale, ball_scale)

func _unfreeze_immediate(player: CharacterBody2D) -> void:
	if is_instance_valid(player):
		player.set_physics_process(true)
		player.is_hitting = false
		player.visual_container.modulate = Color.WHITE # Restaurar a normal
		# Si quisiéramos restaurar el modulate original exacto, necesitaríamos guardarlo,
		# pero Color.WHITE es el estándar.

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
	if sprite:
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2(ball_scale, ball_scale)
		
	if hit_sprite:
		hit_sprite.visible = false

func setup_shockwave() -> void:
	# Crear el nodo de shockwave
	shockwave_node = ColorRect.new()
	shockwave_node.name = "ShockwaveEffect"
	shockwave_node.size = Vector2(3000, 3000)  # Área muy grande para evitar bordes visibles
	shockwave_node.position = Vector2(-1500, -1500)  # Centrado en la pelota
	shockwave_node.z_index = 100  # Por encima de todo
	shockwave_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shockwave_node.visible = false
	
	# Crear y configurar el shader material
	shockwave_material = ShaderMaterial.new()
	var shader = load("res://assets/msc/shockwave.gdshader")
	shockwave_material.shader = shader
	
	# Configurar parámetros para distorsión de pantalla
	shockwave_material.set_shader_parameter("wave_progress", 0.0)
	shockwave_material.set_shader_parameter("wave_strength", 0.05)  # Intensidad de distorsión
	shockwave_material.set_shader_parameter("wave_thickness", 0.12)
	shockwave_material.set_shader_parameter("wave_center", Vector2(0.5, 0.5))
	
	# Configurar color base del ColorRect (completamente transparente)
	shockwave_node.color = Color(0.0, 0.0, 0.0, 0.0)
	
	# Asignar material al ColorRect
	shockwave_node.material = shockwave_material
	
	# Agregar como hijo de la pelota
	add_child(shockwave_node)

func play_shockwave_effect() -> void:
	if shockwave_node == null or shockwave_material == null:
		return
	
	# Hacer visible el efecto
	shockwave_node.visible = true
	
	# Resetear el progreso
	shockwave_material.set_shader_parameter("wave_progress", 0.0)
	
	# Animar la onda de choque durante 1 segundo (duración del freeze)
	var tween = create_tween()
	tween.tween_method(
		func(value: float):
			if shockwave_material:
				shockwave_material.set_shader_parameter("wave_progress", value),
		0.0,
		1.5,  # Expandir más allá del área visible para efecto completo
		1.0   # 1 segundo de duración
	)
	
	# Ocultar después de la animación
	tween.tween_callback(func(): 
		if shockwave_node:
			shockwave_node.visible = false
	)

func play_player_specific_hit_effect(player: CharacterBody2D) -> void:
	if not player:
		return
		
	print("DEBUG: play_player_specific_hit_effect called for player ", player.player_id)
		
	var effect_to_play: AnimatedSprite2D = null
	
	if player.player_id == 1:
		effect_to_play = p1_hit_effect
	elif player.player_id == 2:
		effect_to_play = p2_hit_effect
		
	if effect_to_play:
		print("DEBUG: Playing effect for player ", player.player_id)
		effect_to_play.visible = true
		# Resetear rotación local y aplicar rotación global basada en dirección
		# Como ahora son hijos de visual_pivot, su rotación es relativa al pivote.
		# El pivote YA apunta en la dirección del movimiento (velocity.angle()) en _process
		# Así que si ponemos rotation = 0, deberían apuntar hacia adelante (derecha del pivote).
		effect_to_play.rotation = 0 
		effect_to_play.frame = 0
		effect_to_play.play()
	else:
		print("DEBUG: No effect found to play for player ", player.player_id)
