# Arquitectura del Proyecto - XOC v2

## 📋 Índice
1. [Descripción General](#descripción-general)
2. [Tecnología y Engine](#tecnología-y-engine)
3. [Estructura de Carpetas](#estructura-de-carpetas)
4. [Flujo de Escenas](#flujo-de-escenas)
5. [Sistemas Principales](#sistemas-principales)
6. [Autoloads (Singletons)](#autoloads-singletons)
7. [Sistema de Combate](#sistema-de-combate)
8. [Sistema de Personajes](#sistema-de-personajes)
9. [Sistema de Audio](#sistema-de-audio)
10. [Sistema de Clima](#sistema-de-clima)
11. [Sistema de UI](#sistema-de-ui)
12. [Configuración y Guardado](#configuración-y-guardado)
13. [Mapas y Escenarios](#mapas-y-escenarios)
14. [Efectos Visuales](#efectos-visuales)

---

## Descripción General

**XOC v2** es un juego de combate 1v1 estilo "pong de peleas" desarrollado en Godot 4.5. Dos jugadores controlan personajes que golpean una pelota para intentar dañar al oponente. El último jugador con vidas gana.

### Género
- **Tipo**: Fighting Game / Pong Híbrido
- **Jugadores**: 2 (local multiplayer)
- **Vista**: 2D lateral

### Mecánicas Core
- Golpear pelota para dañar oponente
- Sistema de vidas (3 por defecto)
- Sistema de combos para cargar ultimate
- Movimiento avanzado (sprint, doble salto, wall jump)
- Habilidades ultimate únicas por personaje

---

## Tecnología y Engine

- **Engine**: Godot 4.5
- **Lenguaje**: GDScript
- **Resolución**: 1280x720 (escalado con canvas_items)
- **Sistema de Audio**: Buses separados (Music, SFX, Master)
- **Guardado**: ConfigFile (.cfg)

---

## Estructura de Carpetas

```
godot-xoc-v2/
├── assets/                     # Recursos visuales y audio
│   ├── background/            # Fondos de mapas y menús
│   ├── font/                  # Fuentes tipográficas
│   ├── hud/                   # Elementos de interfaz
│   ├── msc/                   # Misceláneos (bola, efectos)
│   ├── particles/             # Sprites de partículas
│   └── players/               # Personajes
│       ├── don_quixote/
│       │   └── Sprites/       # Sprites del personaje
│       └── ishmael/
│           └── Sprites/
├── scenes/                     # Escenas de Godot
│   ├── ui/                    # Interfaces de usuario
│   ├── character_select.tscn
│   ├── game.tscn
│   ├── intro.tscn
│   ├── main_menu.tscn
│   ├── map_select.tscn
│   ├── options_menu.tscn
│   ├── pause_menu.tscn
│   ├── scene_transition.tscn
│   └── victory_screen.tscn
├── scripts/                    # Lógica GDScript
│   ├── player.gd
│   ├── ball.gd
│   ├── game_manager.gd
│   ├── global.gd
│   └── ... (otros scripts)
├── sound/                      # Audio
│   ├── music/                 # Música de fondo
│   └── sfx/                   # Efectos de sonido
│       ├── golpe/             # Sonidos de golpes
│       ├── players/           # Voces de personajes
│       └── ... (otros efectos)
├── DOCUMENTACION_PERSONAJES.md
├── ARQUITECTURA_PROYECTO.md
└── project.godot
```

---

## Flujo de Escenas

### Diagrama de Navegación

```
intro.tscn
    ↓
main_menu.tscn
    ├─→ options_menu.tscn (volver a main_menu)
    ├─→ profile (futuro)
    └─→ character_select.tscn
            ↓
        map_select.tscn
            ↓
        game.tscn
            ├─→ pause_menu.tscn (overlay)
            └─→ victory_screen.tscn
                    ├─→ Revancha (reset_match → game.tscn)
                    ├─→ Cambiar Personajes (character_select.tscn)
                    └─→ Volver al Menú (main_menu.tscn)
```

### Descripción de Escenas

#### 1. `intro.tscn`
- **Propósito**: Video de introducción
- **Script**: `intro.gd`
- **Características**:
  - Reproduce video intro
  - Puede saltarse con cualquier tecla
  - Respeta configuración `Global.skip_intro`
  - Transición automática a menú principal

#### 2. `main_menu.tscn`
- **Propósito**: Menú principal del juego
- **Script**: `main_menu.gd`
- **Elementos**:
  - Botón JUGAR → character_select
  - Botón PERFIL → (futuro)
  - Botón OPCIONES → options_menu
  - Botón SALIR → cerrar juego
- **Características**:
  - Navegación con teclado (W/S)
  - Animación de selección (sprites se mueven)
  - Música de título
  - Validación de API del clima en background

#### 3. `options_menu.tscn`
- **Propósito**: Configuración del juego
- **Script**: `options_menu.gd`
- **Opciones**:
  - Slider de volumen (0-100%)
  - Checkbox de saltar intro
- **Guardado**: Automático en `user://settings.cfg`

#### 4. `character_select.tscn`
- **Propósito**: Selección de personajes
- **Script**: `character_select.gd`
- **Mecánica**:
  - P1 selecciona con A/D, confirma con Space
  - P2 selecciona con Flechas, confirma con Enter
  - Preview de personaje seleccionado
  - Transición a map_select cuando ambos confirman

#### 5. `map_select.tscn`
- **Propósito**: Selección de mapa
- **Script**: `map_select.gd`
- **Características**:
  - 3 mapas disponibles (navegación circular)
  - Preview visual del mapa seleccionado
  - Muestra clima actual
  - Botón START para comenzar partida

#### 6. `game.tscn`
- **Propósito**: Escena principal de juego
- **Script**: `game_manager.gd`
- **Componentes principales**:
  - Player1 y Player2 (CharacterBody2D)
  - Ball (pelota de combate)
  - HUD (vidas, combos)
  - Camera2D (con zoom en ultimates)
  - Walls (colisiones de escenario)
  - Sistema de clima (lluvia)
  - Sistema de partículas (sprint, jump, landing)

#### 7. `victory_screen.tscn`
- **Propósito**: Pantalla de fin de partida
- **Script**: `victory_screen.gd`
- **Elementos**:
  - Sprite de victoria/derrota
  - Botones de opciones post-partida
  - Música de victoria

#### 8. `pause_menu.tscn`
- **Propósito**: Menú de pausa in-game
- **Características**:
  - Pausa el juego (process_mode = ALWAYS)
  - Continuar o volver al menú

---

## Sistemas Principales

### 1. Sistema de Vidas
- **Ubicación**: `Global.player1_lives`, `Global.player2_lives`
- **Default**: 3 vidas por jugador
- **Mecánica**: 
  - Perder todas las vidas = derrota
  - Vida se pierde cuando la pelota golpea al jugador
  - Se gestiona en `game_manager.gd`

### 2. Sistema de Combos
- **Ubicación**: `player.gd` (`combo_count`)
- **Mecánica**:
  - Cada golpe exitoso a la pelota incrementa combo
  - Máximo: 4 hits
  - Al llegar a 4: `ultimate_ready = true`
  - Se resetea al recibir daño o activar ultimate

### 3. Sistema de Ultimate
- **Ubicación**: `player.gd`
- **Activación**: Presionar Q (P1) o P (P2)
- **Requisito**: `ultimate_ready == true` (4 combos)
- **Efectos**:
  - Zoom de cámara (`game_manager.gd`)
  - Animación de sprites únicos
  - Reproducción de voz del personaje
  - Efecto especial según personaje:
    - **Don Quixote**: Lanza pelota con 999 de daño
    - **Ishmael**: Modo parry por 2 segundos, devuelve pelota con 999 daño si es golpeado

### 4. Sistema de Movimiento
- **Ubicación**: `player.gd` (`_physics_process`)
- **Controles P1**: W/A/S/D (Space para golpear, Q para ultimate)
- **Controles P2**: Flechas (Enter para golpear, P para ultimate)
- **Mecánicas**:
  - **Sprint**: Doble tap A/D o ←/→ (velocidad aumentada)
  - **Salto**: Simple, doble, wall jump
  - **Gravedad**: Aplicada constantemente cuando está en aire
  - **Colisiones**: CharacterBody2D con move_and_slide()

### 5. Sistema de Pelota
- **Ubicación**: `ball.gd`
- **Comportamiento**:
  - Rebota en paredes y techo
  - Acelera con cada golpe (+300 velocidad)
  - Velocidad máxima: 4000
  - Velocidad inicial: 1600
  - Daño base: 25 (escalado por velocidad)
- **Estados**:
  - Normal: Sprite de pelota básica
  - Golpeada: Sprite de impacto + partículas
- **Sonidos**: 
  - Weak hit (velocidad < 2000)
  - Medium hit (2000-3000)
  - Strong hit (> 3000)

---

## Autoloads (Singletons)

Configurados en `project.godot`, disponibles globalmente:

### 1. **Global** (`global.gd`)
- **Propósito**: Estado global del juego
- **Variables clave**:
  - Constantes de física (velocidad, gravedad, etc.)
  - Vidas de jugadores
  - Personajes seleccionados
  - Mapa seleccionado
  - Ganador actual
  - Configuración (skip_intro)
- **Funciones**:
  - `reset_game()`: Reset completo
  - `reset_match()`: Reset solo vidas/ganador
  - `load_settings()`: Cargar configuración guardada
  - `apply_volume()`: Aplicar volumen de audio

### 2. **SceneTransition** (`scene_transition.tscn`)
- **Propósito**: Transiciones entre escenas
- **Funciones**:
  - `fade_to_scene(path)`: Transición suave (menús)
  - `loading_screen_to_scene(path, wait_time)`: Con pantalla de carga (juego)

### 3. **UserProfile** (`user_profile.gd`)
- **Propósito**: Gestión de perfiles (futuro)
- **Variable**: `current_profile_name`

### 4. **MusicManager** (`music_manager.gd`)
- **Propósito**: Control de música de fondo
- **Constantes**: Rutas a archivos de música
  - `TITLE_MUSIC`
  - `CHAR_SELECT_MUSIC`
  - `STAGE_1_MUSIC`, `STAGE_2_MUSIC`, `STAGE_3_MUSIC`
  - `VICTORY_MUSIC`
- **Funciones**:
  - `play_music(path)`: Reproducir música
  - `stop_music()`: Detener música
  - `get_stage_music(index)`: Obtener música según mapa

### 5. **UISounds** (`ui_sounds.gd`)
- **Propósito**: Efectos de sonido de UI
- **Funciones**:
  - `play_select()`: Sonido de selección
  - `play_slide()`: Sonido de navegación
  - `play_cancel()`: Sonido de cancelar

### 6. **WeatherAPI** (`weather_api.gd`)
- **Propósito**: Obtener clima real (OpenWeatherMap)
- **Variables**:
  - `current_weather_type`: String del clima actual
  - `FORCE_TEST_WEATHER`: Bool para modo prueba
- **Señales**:
  - `api_validation_result(is_valid, message)`
- **Funciones**:
  - `fetch_weather()`: Consultar API
- **Categorías de clima**:
  - Claro (800)
  - Nublado (700-799)
  - Lloviendo (500-599)
  - Nevando (600-699)
  - Tormenta (200-299)

---

## Sistema de Combate

### Mecánica de Golpe
**Ubicación**: `player.gd` → `hit()`

1. **Activación**: Presionar Space (P1) o Enter (P2)
2. **Secuencia**:
   - Activar área de golpe (`HitArea`)
   - Cambiar sprites (hit1 → hit1_2 → hit1_3)
   - Animar escala del contenedor visual
   - Reproducir sonido de ataque
3. **Detección**: 
   - `HitArea` detecta colisión con pelota
   - Señal conectada a `ball.gd` → `_on_hit_area_entered()`
4. **Resultado**:
   - Pelota cambia dirección y velocidad
   - Incrementa combo del jugador
   - Reproduce sonido según fuerza

### Mecánica de Daño
**Ubicación**: `player.gd` → `take_damage(damage, knockback_direction)`

1. **Activación**: Pelota colisiona con jugador
2. **Validaciones**:
   - Ignorar si `invulnerable == true`
   - Ignorar si `god_mode == true`
   - Counter si `is_parrying == true` (Ishmael)
3. **Efectos**:
   - Reducir HP
   - Aplicar knockback
   - Sprite de daño + sonido
   - Invulnerabilidad temporal (0.5s con parpadeo)
4. **Muerte**:
   - Si HP ≤ 0: Ejecutar `death_animation()`
   - Emitir señal `player_defeated`
   - Game manager resta vida y verifica ganador

### Hitbox y Posicionamiento
- **HitArea**: Area2D hijo del jugador
- **Posición**: Controlada por `update_hit_area_position()`
- **Fórmula**: `hit_area.position = last_direction * hit_distance + hit_offset`
- **Variables ajustables**:
  - `hit_distance`: Alcance del golpe
  - `hit_offset`: Offset desde el centro
  - `last_direction`: Vector2 normalizado de la última dirección de input

---

## Sistema de Personajes

### Estructura de Datos
Cada personaje tiene un índice único:
- 0 = Don Quixote
- 1 = Ishmael

### Componentes de Personaje

#### 1. Sprites (`sprites` dictionary)
```gdscript
sprites = {
    "idle": Texture2D,
    "move": Texture2D,
    "jump": Texture2D,
    "hit1": Texture2D,
    "hit1_2": Texture2D,
    "hit1_3": Texture2D,
    "block": Texture2D,
    "dmg": Texture2D,
    "ultimate": Texture2D
}
```

#### 2. Ultimate Frames (`ultimate_frames` Array)
Array de Texture2D para animación frame-by-frame del ultimate

#### 3. Offsets de Sprites
Ajustes visuales para cada estado:
- `idle_offset`, `move_offset`, `jump_offset`
- `hit1_offset`, `hit1_2_offset`, `hit1_3_offset`
- `block_offset`, `dmg_offset`, `victory_offset`, `ultimate_offset`

#### 4. Sonidos
- **Ataque**: Array de 3-4 variaciones (`attack_sounds`)
- **Ultimate**: Voz única al activar
- **Hit recibido**: Sonidos compartidos (`hit_sounds`)

#### 5. Hitbox
- `hit_distance`: Float (alcance en píxeles)
- `hit_offset`: Vector2 (ajuste posicional)

### Sistema de Carga
**Función**: `load_character_sprites()`

1. Determinar personaje según `player_id`:
   - P1 → `Global.player1_character`
   - P2 → `Global.player2_character`
2. Construir ruta base:
   - `res://assets/players/[nombre]/Sprites/`
3. Cargar sprites básicos (idle, move, jump, etc.)
4. Cargar frames de ultimate según personaje
5. Activar sprite_node, ocultar placeholder

### Sistema de Setup
**Función**: `setup_character()`

1. Configurar hitbox según personaje
2. Cargar array de sonidos de ataque
3. Configurar offsets de sprites
4. Aplicar sprite inicial (idle)
5. Resetear HP

### Personajes Implementados

#### Don Quixote (Character 0)
- **Estilo**: Combate balanceado
- **Hitbox**: Corto alcance (50px)
- **Ultimate**: "Skill3" - Ataque devastador (999 daño)
- **Mecánica**: Lanza pelota con poder máximo
- **Sprites**: 5 frames de ultimate (skill3_1 a skill3_5)
- **Offsets**: idle_offset.y = -120 (sprite grande)

#### Ishmael (Character 1)
- **Estilo**: Counter/Parry
- **Hitbox**: Largo alcance (100px)
- **Ultimate**: "Ultra" - Modo parry
- **Mecánica**: 2 segundos de parry, devuelve pelota con 999 daño si es golpeado
- **Sprites**: 4 frames de ultimate (ultra_1 a ultra_4)
- **Offsets**: idle_offset.y = 0 (sprite estándar)

---

## Sistema de Audio

### Configuración de Buses
- **Master**: Bus principal (índice 0)
- **Music**: Música de fondo
- **SFX**: Efectos de sonido y voces

### Control de Volumen
- **Ubicación**: `options_menu.gd`
- **Rango**: 0-100%
- **Conversión**: `linear_to_db(volume / 100.0)`
- **Guardado**: `user://settings.cfg`
- **Carga**: `Global.load_settings()` en `_ready()`

### Música del Juego
Gestionada por **MusicManager**:

| Escena | Música |
|--------|--------|
| Intro | (sin música) |
| Main Menu | TITLE_MUSIC |
| Character Select | CHAR_SELECT_MUSIC |
| Map Select | CHAR_SELECT_MUSIC |
| Game | Según mapa (STAGE_1/2/3_MUSIC) |
| Victory | VICTORY_MUSIC |

### Efectos de Sonido

#### UI (`ui_sounds.gd`)
- `slide.wav` - Navegación de menú
- `select.wav` - Confirmación
- `cancel.wav` - Cancelar

#### Combate
- **Golpes a pelota**: 3 niveles según velocidad
  - `weak_hit.wav` (< 2000)
  - `medium_hit.wav` (2000-3000)
  - `strong_hit.wav` (> 3000)
- **Swing**: Golpe al aire sin conectar
- **Hit recibido**: 4 variaciones aleatorias

#### Personajes
- **Ataques**: 3-4 variaciones por personaje
- **Ultimate**: Voz única ("ulti_don.wav", "ulti_ishm.wav")

#### Ambiente
- **Lluvia**: `rain.wav` (loop, volumen según intensidad)
- **Muerte**: `kill.wav`
- **Ultimate activado**: `ultimate.wav`

---

## Sistema de Clima

### Fuente de Datos
- **API**: OpenWeatherMap
- **Endpoint**: `https://api.openweathermap.org/data/2.5/weather`
- **Parámetros**: Ciudad + API Key
- **Frecuencia**: Una consulta al inicio (main menu)

### Modo de Prueba
```gdscript
# weather_api.gd
const FORCE_TEST_WEATHER = true  # Activar/desactivar
const TEST_WEATHER_TYPE = "Lloviendo"  # Clima de prueba
```

### Categorías de Clima
Basado en ID de OpenWeatherMap:
- **Claro** (800): Código 800
- **Nublado** (801-804): Códigos 700-799
- **Lloviendo** (500-531): Códigos 500-599
- **Nevando** (600-622): Códigos 600-699
- **Tormenta** (200-232): Códigos 200-299
- **Llovizna** (300-321): Códigos 300-399

### Efectos en Game
**Ubicación**: `game_manager.gd`

#### Sistema de Lluvia
1. **Detección**: `WeatherAPI.current_weather_type`
2. **Categorías con lluvia**:
   - Llovizna: 250 partículas, volumen -8 dB
   - Lloviendo: 500 partículas, volumen -4 dB
   - Tormenta: 750 partículas, volumen 0 dB
3. **Partículas**: GPUParticles2D
   - Textura: `rain.png`
   - Gravedad: Vector3(0, 980, 0)
   - Spread: 5°
   - Lifetime: 2s
4. **Audio**: Loop de sonido de lluvia

---

## Sistema de UI

### HUD (`hud.tscn`)
Componentes:
- **Vidas P1**: TextureRect con sprite de corazones
- **Vidas P2**: TextureRect con sprite de corazones
- **Combos P1/P2**: Labels de texto
- **Barra de Vida P1/P2**: ProgressBar (visual)

**Script**: `hud.gd`
- Conecta señales de players:
  - `player_damaged` → Actualizar HP visual
  - `combo_changed` → Actualizar texto de combo
- Actualiza vidas desde `Global.player1_lives` / `player2_lives`

### Victory Screen
**Componentes**:
- Sprite de "That's a Wrap"
- Label de ganador
- Sprites animados de botones
- Botones invisibles sobre sprites:
  - **Revancha**: `game_manager.reset_match()` → reload game
  - **Cambiar Personajes**: `Global.reset_game()` → character_select
  - **Volver al Menú**: `Global.reset_game()` → main_menu

**Animación**:
- Entrada: Scale 2.5 → 1.0 con vibración
- Vibración: Solo durante entrada, no constante

### Pause Menu
- Overlay sobre game
- `process_mode = ALWAYS` (funciona en pausa)
- Opciones: Continuar / Volver al Menú
- ESC para pausar/despausar

---

## Configuración y Guardado

### Archivo de Configuración
**Ubicación**: `user://settings.cfg`
**Formato**: ConfigFile (INI-like)

**Estructura**:
```ini
[audio]
volume=100.0

[gameplay]
skip_intro=false
```

### Sistema de Carga
1. **Global._ready()**:
   - Cargar `settings.cfg`
   - Aplicar `skip_intro`
   - Aplicar volumen de audio

2. **options_menu._ready()**:
   - Cargar `settings.cfg`
   - Poblar sliders/checkboxes con valores guardados
   - Aplicar configuración actual

### Sistema de Guardado
- **Trigger**: Cualquier cambio en options_menu
- **Método**: `ConfigFile.save()`
- **Automático**: Sí (cada cambio)

### Valores por Defecto
Si no existe archivo:
- `volume = 100.0` (100%)
- `skip_intro = false`

---

## Mapas y Escenarios

### Mapas Disponibles
1. **Mapa 1**: ARENA CLÁSICA
   - Imagen: `stage_1_new.png`
   - Música: `stg_1.mp3`
   
2. **Mapa 2**: MAPA 2
   - Imagen: `stg_2.png`
   - Música: `stg_2.mp3`
   
3. **Mapa 3**: MAPA 3
   - Imagen: `stg_3.png`
   - Música: `stg_3.mp3`

### Selección de Mapa
- **Escena**: `map_select.tscn`
- **Variable**: `Global.selected_map` (0, 1, o 2)
- **UI**: Botones ◀ / ▶ para navegación circular
- **Preview**: Sprite del mapa seleccionado visible

### Carga en Game
**Función**: `game_manager._setup_map()`
1. Activar TextureRect del mapa correcto
2. Ocultar otros mapas
3. Cargar música correspondiente
4. Aplicar clima si corresponde

### Colisiones
**Nodo**: `Walls` (StaticBody2D)
- TopWall (Y = -20)
- Floor (Y = 692)
- LeftWall (X = -20, rotado 90°)
- RightWall (X = 1300, rotado 90°)

---

## Efectos Visuales

### Partículas de Movimiento
**Ubicación**: `game.tscn` → Dentro de `Player/VisualContainer`

#### 1. Sprint Effect (P1/P2)
- **Tipo**: AnimatedSprite2D
- **Activación**: Cuando `is_sprinting && is_on_floor()`
- **Posición**: 30px detrás del jugador (dirección dinámica)
- **Flip**: Se voltea según dirección

#### 2. Jump Effect (P1/P2)
- **Tipo**: AnimatedSprite2D
- **Activación**: Al saltar (normal, wall, doble)
- **Posición**: Debajo del jugador (Y + 50px)
- **Duración**: 0.3s (luego se oculta)

#### 3. Landing Effect (P1/P2)
- **Tipo**: AnimatedSprite2D
- **Activación**: Al tocar suelo después de estar en aire
- **Posición**: Debajo del jugador (Y + 50px)
- **Duración**: 0.4s (luego se oculta)

**Control**: `player.gd`
- `sprint_effect`, `jump_effect`, `landing_effect`
- Asignados desde `game_manager._ready()`

### Animación de Golpe
- **Ubicación**: `player.hit()`
- **Efecto**: Scale visual_container 1.0 → 1.3 → 1.0
- **Duración**: 0.2s total
- **Indicador**: ColorRect amarillo con fade

### Animación de Daño
- **Sprite**: Cambio a `dmg.png`
- **Parpadeo**: 5 ciclos de alpha 0.3 ↔ 1.0
- **Duración**: 0.5s (INVULNERABILITY_TIME)

### Showtime Intro
- **Sprite**: AnimatedSprite2D con 9 frames
- **Animación**: Loop a 5 FPS × 1.5 speed
- **Trigger**: Al iniciar partida
- **Duración**: Hasta que `game_should_start` es true

### Victoria/Derrota
- **Sprites**: Personajes en pose de victoria
- **Offset**: `victory_offset` específico por personaje
- **Animación**: Entrada con scale + vibración

---

## Constantes de Física

**Ubicación**: `global.gd`

```gdscript
# Jugador
MAX_HP = 100
MAX_LIVES = 3
PLAYER_SPEED = 570
SPRINT_SPEED = 950
JUMP_VELOCITY = -1140
WALL_JUMP_VELOCITY = Vector2(760, -1045)
GRAVITY = 2850
DOUBLE_TAP_TIME = 0.3  # Tiempo para detectar doble tap

# Pelota
INITIAL_BALL_SPEED = 1600
BALL_SPEED_INCREMENT = 300
MAX_BALL_SPEED = 4000

# Combate
BASE_DAMAGE = 25
KNOCKBACK_FORCE = 760
INVULNERABILITY_TIME = 0.5

# Sonidos (umbrales de velocidad)
WEAK_THRESHOLD = 2000
MEDIUM_THRESHOLD = 3000
```

---

## Flujo de Juego Completo

### 1. Inicio del Juego
```
Arrancar juego
    ↓
Global._ready() → Cargar settings.cfg
    ↓
intro.tscn
    ├─ Si skip_intro = true → main_menu directo
    └─ Si skip_intro = false → Reproducir video
```

### 2. Navegación de Menús
```
main_menu.tscn
    ↓ (Presionar JUGAR)
character_select.tscn
    ├─ P1 selecciona personaje
    ├─ P2 selecciona personaje
    └─ Ambos confirman
        ↓
map_select.tscn
    ├─ Navegar entre 3 mapas
    ├─ Ver preview y clima
    └─ Presionar START
        ↓
game.tscn
```

### 3. Partida de Juego
```
game.tscn carga
    ↓
game_manager._ready()
    ├─ Cargar clima y activar lluvia si aplica
    ├─ Setup mapa seleccionado
    ├─ Reproducir música del mapa
    ├─ Conectar señales de players
    └─ Conectar efectos visuales
        ↓
Animación "SHOWTIME"
    ↓
game_should_start = true
    ↓
LOOP DE JUEGO:
    ├─ Players se mueven y golpean
    ├─ Pelota rebota y daña
    ├─ Sistema de combos se acumula
    ├─ Ultimates se activan
    └─ HP y vidas disminuyen
        ↓
player_defeated signal
    ↓
game_manager._on_player_defeated()
    ├─ Restar vida al jugador
    ├─ Verificar si quedan vidas
    └─ Si vidas = 0 → Determinar ganador
        ↓
victory_overlay aparece
```

### 4. Fin de Partida
```
victory_screen visible
    ↓
Opciones:
├─ REVANCHA
│   ├─ Global.reset_match()
│   └─ SceneTransition → game.tscn
│
├─ CAMBIAR PERSONAJES
│   ├─ Global.reset_game()
│   └─ SceneTransition → character_select.tscn
│
└─ VOLVER AL MENÚ
    ├─ Global.reset_game()
    └─ SceneTransition → main_menu.tscn
```

---

## Señales Principales

### Player Signals
```gdscript
signal player_damaged(player_id: int, damage: float)
signal player_defeated(player_id: int)
signal combo_changed(player_id: int, combo: int)
signal ultimate_activated(player_id: int)
signal don_ultimate_attack()  # Don Quixote
signal ishmael_parry_hit()     # Ishmael
signal ishmael_parry_success() # Ishmael
```

### Game Manager Connections
- `player1.player_damaged` → `_on_player_damaged()`
- `player1.player_defeated` → `_on_player_defeated()`
- `player1.combo_changed` → HUD update
- `player1.ultimate_activated` → Camera zoom
- `player1.don_ultimate_attack` → Launch ball with 999 damage
- `player1.ishmael_parry_success` → Reverse ball with 999 damage

### Ball Signals
- `ball.entered_player_area(player_id)` → Damage player

---

## Capas de Colisión

| Layer | Nombre | Uso |
|-------|--------|-----|
| 1 | Player | Jugadores |
| 2 | Ball | Pelota |
| 3 | Wall | Paredes y suelo |
| 4 | HitArea | Área de golpe de jugadores |

**Máscaras de Colisión**:
- **Player**: Detecta Wall (capa 3) + Ball (capa 2)
- **Ball**: Detecta Player (capa 1) + Wall (capa 3)
- **HitArea**: Detecta solo Ball (capa 2)

---

## Debug y Testing

### Modos de Debug
```gdscript
# global.gd
var god_mode: bool = false  # Invulnerabilidad
var debug_one_hit_kill: bool = false  # Matar en un golpe
```

### Weather Test Mode
```gdscript
# weather_api.gd
const FORCE_TEST_WEATHER = true
const TEST_WEATHER_TYPE = "Lloviendo"
```

### Logs Importantes
- "Player X cargando character: Y" - Carga de personaje
- "Ruta sprites: ..." - Path de sprites
- "Sprites cargados correctamente!" - Confirmación de carga
- "Player X activando sprint/jump/landing effect" - Efectos visuales
- "¡ACTIVANDO ULTIMATE Player X!" - Ultimate activado

---

## Comandos de Desarrollo

### Controles
- **P1**: W/A/S/D (movimiento), Space (golpe), Q (ultimate)
- **P2**: Flechas (movimiento), Enter (golpe), P (ultimate)
- **ESC**: Pausar juego
- **Doble tap A/D o ←/→**: Activar sprint

### Respawn de Jugador
Automático cuando pierde vida:
- P1 respawnea en (200, 600)
- P2 respawnea en (1080, 600)
- 1 segundo de invulnerabilidad

---

## Optimizaciones

### Física
- `move_and_slide()` en lugar de cálculo manual
- Colisiones basadas en capas (evita checks innecesarios)

### Renderizado
- Sprites ocultos cuando no se usan
- Partículas detienen emisión cuando inactivas

### Audio
- Reutilización de AudioStreamPlayer
- `queue_free()` después de one-shots (voces de ultimate)

### Transiciones
- Fade out/in en lugar de carga instantánea
- Loading screen para game.tscn (escena pesada)

---

## Extensibilidad

### Agregar Nuevo Personaje
Ver: `DOCUMENTACION_PERSONAJES.md`
- Crear carpeta de assets
- Agregar sprites y sonidos
- Modificar 6 puntos en `player.gd`
- Implementar función de ultimate

### Agregar Nuevo Mapa
1. Agregar imagen en `assets/background/`
2. Agregar música en `sound/music/`
3. Crear constante en `music_manager.gd`
4. Agregar TextureRect en `game.tscn`
5. Actualizar `_setup_map()` en `game_manager.gd`
6. Agregar nombre en `MAP_NAMES` (map_select.gd)
7. Agregar sprite preview en `map_select.tscn`

### Agregar Nueva Mecánica de Ultimate
1. Definir señal en `player.gd` (ej: `signal new_ultimate()`)
2. Crear función `execute_new_character_ultimate()`
3. Emitir señal en momento apropiado
4. Conectar señal en `game_manager.gd`
5. Implementar lógica de efecto

---

## Notas Técnicas

### Coordenadas
- **Origen**: Esquina superior izquierda (0, 0)
- **Y positivo**: Hacia abajo
- **Y negativo**: Hacia arriba
- **Pantalla**: 1280 × 720

### Tiempo
- `delta`: Tiempo entre frames (~0.016s a 60 FPS)
- `get_tree().create_timer(seconds)`: Temporizador one-shot
- `Time.get_ticks_msec()`: Milisegundos desde inicio

### Vectores
- `Vector2(x, y)`: Posiciones 2D
- `Vector3(x, y, z)`: Para partículas (Z ignorada en 2D)
- `.normalized()`: Convertir a vector unitario
- `.length()`: Magnitud del vector

### Recursos
- `load(path)`: Cargar recurso (bloqueante)
- `ResourceLoader.exists(path)`: Verificar existencia
- `res://`: Ruta desde raíz del proyecto
- `user://`: Ruta de datos de usuario

---

## Resumen para Agentes IA

**Cuando trabajes con este proyecto**:

1. **Personajes**: Todo está centralizado en `player.gd`, índices numéricos (0, 1, 2...)
2. **Escenas**: Flujo lineal intro → menu → character → map → game
3. **Audio**: Tres buses (Master, Music, SFX), controlados desde Global
4. **Guardado**: Solo en `options_menu`, carga en `Global._ready()`
5. **Combate**: Pelota + HitArea + Señales
6. **UI**: HUD separado, victory como overlay
7. **Clima**: Una consulta al inicio, efectos visuales en game
8. **Partículas**: AnimatedSprite2D, asignadas desde game_manager

**Archivos clave para modificar**:
- Nuevo personaje → `player.gd`
- Nueva escena → Crear .tscn + script
- Nuevo mapa → `game_manager.gd` + `map_select.gd`
- Nueva mecánica → Señal en origen + conexión en game_manager
- Nueva configuración → `options_menu.gd` + `global.gd`

**Nunca modificar directamente**:
- `project.godot` (usar editor)
- Archivos `.import` (autogenerados)
- `user://settings.cfg` (gestionado por ConfigFile)
