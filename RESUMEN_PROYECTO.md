# XOC v2 - Resumen del Proyecto

## 🎮 ¿Qué es XOC v2?

XOC v2 es un **juego de combate 2D híbrido entre Pong y Fighting Game** desarrollado en Godot 4.5. Dos jugadores controlan personajes inspirados en Limbus Company que deben golpear una pelota para dañar al oponente. El objetivo es reducir las vidas del rival a cero.

### Concepto Principal
En lugar de golpearse directamente, los jugadores **golpean una pelota** que rebota por la arena. Cuando la pelota impacta a un jugador, este pierde HP. Si el HP llega a 0, pierde una vida y respawnea. El último jugador con vidas gana la partida.

---

## 🕹️ Mecánicas de Juego

### Sistema de Combate
1. **Golpear la Pelota**: Presiona Space (P1) o Enter (P2) para golpear
2. **Dirección del Golpe**: Usa las teclas direccionales mientras golpeas para dirigir la pelota
3. **Velocidad Creciente**: Cada golpe acelera la pelota (+300 velocidad, máximo 4000)
4. **Daño Escalado**: El daño aumenta con la velocidad de la pelota

### Sistema de Movimiento
- **Caminar**: A/D (P1) o Flechas ←/→ (P2)
- **Sprint**: Doble tap A/D o Flechas para sprintar (velocidad x1.67)
- **Salto**: W (P1) o Flecha ↑ (P2)
- **Doble Salto**: Presiona salto dos veces en el aire
- **Wall Jump**: Salta mientras tocas una pared

### Sistema de Combos y Ultimate
- **Combos**: Cada golpe exitoso a la pelota incrementa tu combo (+1)
- **Ultimate Ready**: Al llegar a 4 combos, tu ultimate se carga
- **Activar Ultimate**: Q (P1) o P (P2)
- **Efectos**: Cada personaje tiene un ultimate único con efectos especiales

### Personajes Disponibles

#### Don Quixote
- **Estilo**: Balanceado, alcance corto
- **Ultimate "Skill 3"**: Lanza la pelota con 999 de daño devastador
- **Hitbox**: 50px (combate cercano)

#### Ishmael
- **Estilo**: Counter, alcance largo
- **Ultimate "Ultra"**: Modo parry de 2 segundos - si te golpean, devuelves la pelota con 999 de daño
- **Hitbox**: 100px (combate a distancia)

---

## 🎯 Flujo de Juego

### 1. Inicio
```
Video Intro → Menú Principal → Selección de Personajes → Selección de Mapa → Partida
```

### 2. Partida
1. **Aparece "SHOWTIME"**: Animación de inicio
2. **La pelota aparece**: Comienza el combate
3. **Los jugadores golpean**: La pelota rebota entre ellos
4. **Daño e Invulnerabilidad**: Al recibir daño, 0.5s de invulnerabilidad con parpadeo
5. **Muerte**: Si HP = 0, pierdes una vida y respawneas
6. **Victoria**: Cuando un jugador pierde todas sus vidas (3 por defecto)

### 3. Post-Partida
Opciones en pantalla de victoria:
- **Revancha**: Reinicia la partida con los mismos personajes
- **Cambiar Personajes**: Vuelve a la selección de personajes
- **Volver al Menú**: Regresa al menú principal

---

## 🛠️ Tecnología

### Motor y Lenguaje
- **Engine**: Godot 4.5
- **Lenguaje**: GDScript
- **Resolución**: 1280x720

### Estructura del Proyecto
```
godot-xoc-v2/
├── assets/          # Sprites, audio, fuentes
├── scenes/          # Escenas de Godot (.tscn)
├── scripts/         # Lógica del juego (.gd)
└── sound/           # Música y efectos de sonido
```

### Sistemas Principales

#### 1. **Sistema de Física**
- Gravedad: 2850
- CharacterBody2D para jugadores
- RigidBody2D para la pelota
- Rebotes realistas con `bounce()` y normales de colisión

#### 2. **Sistema de Audio**
- **3 Buses**: Master, Music, SFX
- **Música Dinámica**: Cambia según la escena (menú, selección, partida, victoria)
- **SFX Adaptativos**: Sonidos de golpe según la velocidad de la pelota (débil/medio/fuerte)

#### 3. **Sistema de Clima** (API de OpenWeatherMap)
- Consulta el clima real de tu ubicación
- **Efectos Visuales**: Si llueve, aparece lluvia en la partida
- **Intensidad Variable**: Llovizna (250 partículas) → Lluvia (500) → Tormenta (750)
- **Audio Ambiental**: Sonido de lluvia que varía con la intensidad

#### 4. **Sistema de Guardado**
- **ConfigFile**: Guarda configuración en `user://settings.cfg`
- **Opciones Guardadas**: 
  - Volumen de audio (0-100%)
  - Saltar intro (sí/no)

#### 5. **Sistema de Efectos Visuales**
Efectos de partículas con AnimatedSprite2D:
- **Sprint**: Estela detrás del personaje mientras corre
- **Salto**: Explosión al despegar del suelo
- **Aterrizaje**: Impacto al caer

#### 6. **Sistema de Cámara**
- **Zoom Dinámico**: La cámara hace zoom cuando se activa un ultimate
- **Shake**: Vibración al recibir golpes fuertes
- **Follow**: Sigue el centro de acción entre los dos jugadores

---

## 📊 Arquitectura del Código

### Autoloads (Singletons Globales)
Scripts que existen durante todo el juego:

1. **Global** (`global.gd`)
   - Variables de juego (vidas, personajes seleccionados, mapa)
   - Constantes de física (velocidades, gravedad, daño)
   - Configuración (skip_intro, god_mode)

2. **SceneTransition** (`scene_transition.tscn`)
   - Transiciones suaves entre escenas con fade
   - Pantalla de carga para escenas pesadas

3. **MusicManager** (`music_manager.gd`)
   - Control centralizado de música de fondo
   - Rutas a todas las pistas del juego

4. **UISounds** (`ui_sounds.gd`)
   - Sonidos de interfaz (select, slide, cancel)

5. **WeatherAPI** (`weather_api.gd`)
   - Consulta API de clima
   - Categorización del clima actual

### Scripts Principales

#### `player.gd` (Controlador de Personaje)
- **Funciones principales**:
  - `_physics_process()`: Movimiento, física, input
  - `hit()`: Lógica de golpeo
  - `take_damage()`: Recibir daño, knockback, muerte
  - `activate_ultimate()`: Ultimate específico de cada personaje
  - `load_character_sprites()`: Cargar sprites según personaje seleccionado
  
#### `ball.gd` (Pelota de Combate)
- **Funciones principales**:
  - `_physics_process()`: Movimiento y colisiones
  - `calculate_damage()`: Daño según velocidad
  - `bounce()`: Rebotes en paredes
  - `reset_ball()`: Reiniciar posición y velocidad

#### `game_manager.gd` (Orquestador de Partida)
- **Funciones principales**:
  - `_ready()`: Setup de partida (clima, música, mapa)
  - `_on_player_defeated()`: Gestión de muerte de jugador
  - `respawn_round()`: Reiniciar ronda tras muerte
  - `end_game()`: Pantalla de victoria
  - `camera_zoom_ultimate()`: Efectos de cámara

---

## 🎨 Escenas del Juego

### 1. **intro.tscn** - Video de Introducción
- Reproduce video intro
- Puede saltarse con cualquier tecla o automáticamente (si está configurado)

### 2. **main_menu.tscn** - Menú Principal
- 4 Botones: Jugar, Perfil, Opciones, Salir
- Navegación con teclado (W/S) o ratón
- Validación de API del clima en background

### 3. **character_select.tscn** - Selección de Personajes
- P1 navega con A/D, confirma con Space
- P2 navega con flechas, confirma con Enter
- Preview del personaje seleccionado

### 4. **map_select.tscn** - Selección de Mapa
- 3 mapas disponibles
- Preview visual del mapa
- Muestra clima actual
- Navegación circular (◀ / ▶)

### 5. **game.tscn** - Partida Principal
Componentes:
- **Player1 y Player2**: CharacterBody2D
- **Ball**: Pelota de combate
- **HUD**: Vidas, HP, combos, velocidad de pelota
- **Camera2D**: Con zoom y shake
- **Walls**: Límites del escenario
- **RainParticles**: Sistema de clima
- **Efectos visuales**: Sprint, jump, landing (x2 para cada jugador)

### 6. **pause_menu.tscn** - Menú de Pausa
- ESC para pausar/despausar
- Opciones de debug (God Mode, One-Hit Kill)
- Volver al menú principal

### 7. **victory_screen.tscn** - Pantalla de Victoria
- Muestra ganador
- 3 opciones: Revancha, Cambiar Personajes, Volver al Menú
- Animación de entrada con vibración

### 8. **options_menu.tscn** - Opciones
- Slider de volumen (Master)
- Checkbox para saltar intro
- Guardado automático de configuración

---

## 🔄 Ciclo de Vida de una Partida

### Fase 1: Inicialización
```
game_manager._ready()
├─ Cargar clima desde WeatherAPI
├─ Activar lluvia si corresponde
├─ Setup del mapa seleccionado
├─ Cargar música del mapa
├─ Conectar señales de jugadores
└─ Asignar efectos visuales
```

### Fase 2: Inicio de Ronda
```
Animación "SHOWTIME"
├─ 9 frames a 5 FPS
└─ Después de 1.5s → game_should_start = true
    ├─ Pelota aparece en centro
    └─ Jugadores pueden moverse
```

### Fase 3: Combate
```
Loop de combate:
├─ Jugadores se mueven y golpean
├─ Pelota rebota y acelera
├─ Al golpear: combo++ 
├─ Al recibir daño: HP-- → knockback → invulnerabilidad 0.5s
├─ Si HP = 0 → animación de muerte
│   ├─ Rebotes contra paredes
│   ├─ Rotación suave
│   ├─ Fade out gradual
│   └─ Cae fuera de pantalla (5s)
└─ Respawn después de muerte
```

### Fase 4: Fin de Partida
```
Cuando vidas = 0:
├─ Determinar ganador
├─ Música de victoria
├─ Overlay de victoria
└─ Opciones post-partida
```

---

## ⚙️ Constantes y Configuración

### Física del Jugador
```gdscript
MAX_HP = 100                    # HP máximo
MAX_LIVES = 3                   # Vidas por jugador
PLAYER_SPEED = 570              # Velocidad caminando
SPRINT_SPEED = 950              # Velocidad sprintando
JUMP_VELOCITY = -1140           # Fuerza de salto
WALL_JUMP_VELOCITY = Vector2(760, -1045)
GRAVITY = 2850                  # Gravedad aplicada
```

### Física de la Pelota
```gdscript
INITIAL_BALL_SPEED = 1600       # Velocidad inicial
BALL_SPEED_INCREMENT = 300      # Incremento por golpe
MAX_BALL_SPEED = 4000           # Velocidad máxima
```

### Combate
```gdscript
BASE_DAMAGE = 25                # Daño base
KNOCKBACK_FORCE = 760           # Fuerza de knockback
INVULNERABILITY_TIME = 0.5      # Tiempo invulnerable (segundos)
```

### Audio (Umbrales de velocidad de pelota)
```gdscript
WEAK_THRESHOLD = 2000           # < 2000 = golpe débil
MEDIUM_THRESHOLD = 3000         # 2000-3000 = medio
                               # > 3000 = golpe fuerte
```

---

## 🎯 Señales y Comunicación

### Señales del Player
```gdscript
signal player_damaged(player_id: int, damage: float)
signal player_defeated(player_id: int)
signal combo_changed(player_id: int, combo: int)
signal ultimate_activated(player_id: int)
signal don_ultimate_attack()      # Don Quixote lanza pelota
signal ishmael_parry_hit()        # Ishmael recibe golpe en parry
signal ishmael_parry_success()    # Ishmael devuelve pelota
```

### Flujo de Señales
```
Player golpea pelota
    ↓
Ball.velocity cambia
    ↓
Ball colisiona con Player enemigo
    ↓
Player.take_damage(damage, knockback)
    ↓
player_damaged.emit() → HUD actualiza HP
    ↓
Si HP <= 0:
    player_defeated.emit() → game_manager resta vida
        ↓
    death_animation() → rebotes y caída
        ↓
    respawn_round() → jugador reaparece
```

---

## 🔧 Sistema de Personajes

### Anatomía de un Personaje

Cada personaje necesita:

1. **Carpeta de Assets**: `assets/players/[nombre]/`
   - `Sprites/`: 11 archivos PNG mínimo
   - `attack/`: 3-4 sonidos WAV de ataque
   - `ulti_[nombre].wav`: Voz de ultimate

2. **Sprites Requeridos**:
   - `idle.png` - Postura de espera
   - `move.png` - Caminando
   - `jump.png` - Saltando
   - `hit1.png`, `hit1_2.png`, `hit1_3.png` - Secuencia de golpe
   - `dmg.png` - Recibiendo daño
   - `block.png` - Bloqueando
   - `ultimate_1.png` a `ultimate_4.png` - Frames de ultimate

3. **Código en `player.gd`**:
   - `load_character_sprites()`: Cargar sprites según índice
   - `setup_character()`: Configurar hitbox y sonidos
   - `activate_ultimate()`: Lógica del ultimate

4. **Parámetros Únicos**:
   - `hit_distance`: Alcance del golpe (50-100px)
   - `hit_offset`: Ajuste de posición del hitbox
   - `sprite_offsets`: Ajustes visuales por estado (idle, move, jump, etc.)
   - `attack_sounds`: Array de sonidos de ataque

### Índices de Personajes
```gdscript
0 = Don Quixote
1 = Ishmael
2+ = Futuros personajes
```

---

## 🌍 Sistema de Clima en Tiempo Real

### Flujo de Clima
```
main_menu carga
    ↓
weather_api.gd consulta OpenWeatherMap
    ↓
Respuesta con código de clima (ej: 500 = lluvia)
    ↓
Categorización:
├─ 200-299 → Tormenta
├─ 300-399 → Llovizna  
├─ 500-599 → Lloviendo
├─ 600-699 → Nevando
├─ 700-799 → Nublado
└─ 800 → Claro
    ↓
Global.current_weather_type = "Lloviendo"
    ↓
game_manager lee el clima
    ↓
Si lluvia/tormenta/llovizna:
├─ Activar GPUParticles2D
├─ Configurar cantidad según intensidad
└─ Reproducir sonido de lluvia
```

### Efectos por Tipo de Clima
- **Llovizna**: 250 partículas, volumen -8dB
- **Lloviendo**: 500 partículas, volumen -4dB
- **Tormenta**: 750 partículas, volumen 0dB

---

## 🎵 Sistema de Audio

### Estructura de Buses
```
Master (Bus 0)
├─ Music (Bus 1)
│  ├─ Música de título
│  ├─ Música de selección
│  ├─ Música de mapas
│  └─ Música de victoria
└─ SFX (Bus 2)
   ├─ Golpes a pelota
   ├─ Voces de personajes
   ├─ Efectos UI
   ├─ Sonidos de ambiente
   └─ Efectos especiales
```

### Control de Volumen
- **Slider en Options**: 0-100%
- **Conversión**: `linear_to_db(volume / 100.0)`
- **Aplicación**: `AudioServer.set_bus_volume_db(0, db)`
- **Persistencia**: Guardado en `settings.cfg`

### Música por Escena
| Escena | Música |
|--------|--------|
| Intro | Sin música |
| Main Menu | TITLE_MUSIC |
| Character Select | CHAR_SELECT_MUSIC |
| Map Select | CHAR_SELECT_MUSIC |
| Game - Mapa 1 | STAGE_1_MUSIC |
| Game - Mapa 2 | STAGE_2_MUSIC |
| Game - Mapa 3 | STAGE_3_MUSIC |
| Victory | VICTORY_MUSIC |

---

## 🗺️ Mapas Disponibles

### Mapa 1: ARENA CLÁSICA
- Background: `stage_1_new.png`
- Música: `stg_1.mp3`
- Tema: Arena tradicional

### Mapa 2: MAPA 2
- Background: `stg_2.png`
- Música: `stg_2.mp3`

### Mapa 3: MAPA 3
- Background: `stg_3.png`
- Música: `stg_3.mp3`

### Colisiones Compartidas
Todos los mapas usan las mismas colisiones:
- **TopWall**: Y = -20
- **Floor**: Y = 692
- **LeftWall**: X = -20
- **RightWall**: X = 1300

---

## 🎨 Efectos Visuales y Animaciones

### Partículas de Movimiento (AnimatedSprite2D)

#### Sprint Effect
- **Cuando**: `is_sprinting && is_on_floor()`
- **Ubicación**: 30px detrás del jugador
- **Comportamiento**: Se voltea según dirección
- **Control**: Visible mientras sprintea, invisible al parar

#### Jump Effect
- **Cuando**: Al saltar (normal, wall jump, doble salto)
- **Ubicación**: Debajo del jugador (Y + 50px)
- **Duración**: 0.3 segundos
- **Comportamiento**: Burst único, luego se oculta

#### Landing Effect
- **Cuando**: Al aterrizar después de estar en aire
- **Ubicación**: Debajo del jugador (Y + 50px)
- **Duración**: 0.4 segundos
- **Detección**: Flag `was_in_air` para evitar falsos positivos

### Animaciones de Combate

#### Golpe
```gdscript
1. Activar HitArea (monitoring = true)
2. Cambiar sprites: hit1 → hit1_2 → hit1_3 (0.05s cada uno)
3. Escalar visual_container: 1.0 → 1.3 → 1.0 (0.2s total)
4. Indicador amarillo con fade (ColorRect)
5. Reproducir sonido de ataque aleatorio
```

#### Recibir Daño
```gdscript
1. Cambiar a sprite "dmg"
2. Aplicar knockback: velocity = knockback_dir * 760
3. Efecto de parpadeo:
   ├─ 5 ciclos de alpha 0.3 ↔ 1.0
   └─ Duración: 0.5s (INVULNERABILITY_TIME)
4. Reproducir sonido de daño aleatorio
```

#### Muerte
```gdscript
1. Sprite de daño + sonido
2. Impulso inicial (horizontal + vertical)
3. Loop de física (5 segundos):
   ├─ Gravedad reducida (60%)
   ├─ Rotación suave
   ├─ Rebotes en paredes/techo (dampening 0.5)
   └─ Fade out gradual al salir de pantalla
4. Termina al caer fuera (Y > 1400)
```

### Animaciones de Ultimate

#### Don Quixote - "Skill 3"
```gdscript
1. Zoom de cámara (2.0)
2. Animación de sprites: skill3_1 → skill3_2 → skill3_3 → skill3_4 → skill3_5
3. Voz: "ulti_don.wav"
4. Último frame: Lanza señal don_ultimate_attack
5. game_manager: Dispara pelota con velocidad 3000 y 999 daño
```

#### Ishmael - "Ultra"
```gdscript
1. Zoom de cámara (2.0)
2. Animación de sprites: ultra_1 → ultra_2 → ultra_3 → ultra_4
3. Voz: "ulti_ishm.wav"
4. is_parrying = true por 2 segundos
5. Si recibe daño durante parry:
   ├─ Señal: ishmael_parry_success
   └─ game_manager: Invierte pelota con velocidad 3000 y 999 daño
```

---

## 🔍 Debug y Testing

### Modos de Debug (Pause Menu)

#### God Mode
- **Efecto**: Jugadores son invulnerables
- **Variable**: `Global.god_mode`
- **Uso**: Testing de mecánicas sin morir

#### One-Hit Kill
- **Efecto**: Cada golpe hace 999 de daño
- **Variable**: `Global.debug_one_hit_kill`
- **Uso**: Testing rápido de muerte y respawn

### Logs Importantes
```
"Player X cargando character: Y"           → Carga de personaje iniciada
"Ruta sprites: [path]"                     → Path de sprites
"Sprites cargados correctamente!"          → Confirmación de carga
"Player X activando sprint/jump effect"    → Activación de efectos visuales
"¡ACTIVANDO ULTIMATE Player X!"            → Ultimate activado
"Iniciando animación de muerte"            → Muerte detectada
"Knockback direction recibido: [vector]"   → Debug de muerte
"Rebote en pared izquierda/derecha"        → Rebotes durante muerte
```

---

## 📁 Archivos de Configuración

### `project.godot`
Configuración del proyecto Godot:
- **Resolución**: 1280x720, escalado canvas_items
- **Autoloads**: Global, SceneTransition, MusicManager, etc.
- **Input Map**: Definición de controles P1 y P2
- **Capas de Colisión**: Player, Ball, Wall, HitArea

### `user://settings.cfg`
Guardado de configuración del usuario:
```ini
[audio]
volume=100.0

[gameplay]
skip_intro=false
```

---

## 🎮 Controles

### Jugador 1
| Acción | Tecla |
|--------|-------|
| Mover Izquierda | A |
| Mover Derecha | D |
| Saltar | W |
| Bajar (direccionar golpe) | S |
| Golpear | Space |
| Ultimate | Q |
| Sprint | Doble tap A/D |

### Jugador 2
| Acción | Tecla |
|--------|-------|
| Mover Izquierda | ← |
| Mover Derecha | → |
| Saltar | ↑ |
| Bajar (direccionar golpe) | ↓ |
| Golpear | Enter |
| Ultimate | P |
| Sprint | Doble tap ←/→ |

### Generales
| Acción | Tecla |
|--------|-------|
| Pausar | ESC |
| Saltar Intro | Cualquier tecla |

---

## 🚀 Cómo Funciona Todo Junto

### Ejemplo: Secuencia Completa de Combate

1. **Inicio de Partida**
   ```
   game.tscn carga
   → game_manager setup (clima, mapa, música)
   → Animación SHOWTIME
   → game_should_start = true
   ```

2. **Primer Golpe**
   ```
   P1 presiona Space
   → player1.hit()
   → HitArea activa
   → Secuencia de sprites (hit1 → hit1_2 → hit1_3)
   → Sonido de ataque
   ```

3. **Pelota Golpeada**
   ```
   HitArea colisiona con Ball
   → Ball._on_hit_area_entered()
   → ball.velocity = direccion_golpe * nueva_velocidad
   → ball.speed += 300
   → ball_speed_changed.emit() → HUD actualiza
   → player1.combo++ → combo_changed.emit()
   → Sonido según velocidad (weak/medium/strong)
   ```

4. **Pelota Impacta P2**
   ```
   Ball colisiona con Player2
   → ball.calculate_damage()
   → player2.take_damage(damage, knockback_dir)
   → player2.hp -= damage
   → player_damaged.emit() → HUD actualiza HP
   → Knockback aplicado
   → Sprite de daño + parpadeo
   → Invulnerabilidad 0.5s
   → Combo de P1 se resetea
   ```

5. **Combo Lleno → Ultimate**
   ```
   P1 llega a 4 combos
   → ultimate_ready = true
   → P1 presiona Q
   → activate_ultimate()
   → Zoom de cámara
   → Animación de sprites ultimate
   → Voz del personaje
   → don_ultimate_attack.emit()
   → game_manager recibe señal
   → Pelota disparada con 999 daño
   ```

6. **Muerte de P2**
   ```
   P2 recibe golpe letal
   → hp <= 0
   → player_defeated.emit()
   → death_animation(knockback_dir)
   → Rebotes, rotación, fade out (5s)
   → game_manager._on_player_defeated()
   → Global.player_lost_life(2)
   → HUD actualiza vidas
   → Verificar game over
   → respawn_round(2)
   ```

7. **Respawn**
   ```
   Esperar animación de muerte
   → Desactivar pelota
   → Esperar 1s
   → player2.respawn(SPAWN_P2)
   → Invulnerabilidad 1s
   → Esperar 1s
   → Reactivar pelota en centro
   → Continuar combate
   ```

8. **Victoria**
   ```
   P2 pierde todas sus vidas (0 vidas restantes)
   → Global.check_game_over() = true
   → game_manager.end_game()
   → Global.winner = 1
   → Música de victoria
   → victory_overlay visible
   → Opciones: Revancha / Cambiar / Menú
   ```

---

## 🎓 Resumen para Desarrolladores

### Puntos Clave del Proyecto

1. **Sistema de Señales**: Todo se comunica mediante señales de Godot
2. **Autoloads**: Estado global accesible desde cualquier escena
3. **Física Integrada**: CharacterBody2D + move_and_slide() para jugadores
4. **AnimatedSprite2D**: Efectos visuales simples y editables
5. **ConfigFile**: Persistencia sencilla de configuración
6. **API Externa**: Integración con OpenWeatherMap para clima real

### Extensibilidad

**Para agregar un nuevo personaje**:
1. Crear carpeta en `assets/players/[nombre]/`
2. Agregar 11 sprites + sonidos
3. Modificar 6 puntos en `player.gd`
4. Implementar función de ultimate

**Para agregar un nuevo mapa**:
1. Agregar imagen y música
2. Crear TextureRect en `game.tscn`
3. Actualizar `_setup_map()` en `game_manager.gd`
4. Agregar preview en `map_select.tscn`

**Para agregar una nueva mecánica**:
1. Definir señal en script origen
2. Emitir señal en momento apropiado
3. Conectar señal en `game_manager._ready()`
4. Implementar lógica en receptor

---

## 📈 Estadísticas del Proyecto

- **Escenas**: 12 archivos .tscn
- **Scripts**: 15+ archivos .gd
- **Personajes**: 2 (Don Quixote, Ishmael)
- **Mapas**: 3 escenarios
- **Sistemas**: 10+ subsistemas interconectados
- **Señales**: 15+ señales personalizadas
- **Efectos Visuales**: 6 efectos de partículas (3 por jugador)
- **Archivos de Audio**: 20+ (música + SFX + voces)

---

## 🎯 Conclusión

XOC v2 es un **juego de combate competitivo local** que combina mecánicas de pong con elementos de fighting games. Su arquitectura modular basada en señales permite fácil extensión y mantenimiento. El uso de sistemas externos (clima API) y efectos visuales dinámicos crea una experiencia única en cada partida.

El proyecto demuestra:
- ✅ Gestión avanzada de estados de juego
- ✅ Sistema de física realista con rebotes
- ✅ Integración de API externa
- ✅ Persistencia de datos
- ✅ Audio dinámico y reactivo
- ✅ Efectos visuales procedurales
- ✅ Arquitectura escalable y mantenible

**Para más detalles técnicos**, consulta:
- `ARQUITECTURA_PROYECTO.md` - Documentación técnica completa
- `DOCUMENTACION_PERSONAJES.md` - Guía de creación de personajes
