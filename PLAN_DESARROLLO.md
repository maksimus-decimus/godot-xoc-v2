# 📋 Plan de Desarrollo - Juego Lethal League 2D

## Descripción General
Videojuego 2D inspirado en Lethal League Blaze donde dos jugadores golpean una bola que aumenta de velocidad. El jugador que pierde sus 3 vidas es derrotado.

---

## 🗂️ Estructura del Proyecto

```
nuevo-proyecto-de-juego/
│
├── scenes/
│   ├── main_menu.tscn          # Menú principal
│   ├── character_select.tscn   # Selección de personajes
│   ├── map_select.tscn         # Selección de mapa
│   ├── game.tscn               # Escena principal del juego
│   ├── victory_screen.tscn     # Pantalla de victoria
│   └── ui/
│       └── hud.tscn            # HUD con vidas y salud
│
├── scripts/
│   ├── main_menu.gd
│   ├── character_select.gd
│   ├── map_select.gd
│   ├── game_manager.gd         # Controlador principal del juego
│   ├── player.gd               # Lógica del jugador
│   ├── ball.gd                 # Lógica de la bola
│   ├── victory_screen.gd
│   └── global.gd               # Variables globales (autoload)
│
└── assets/
    ├── players/                # Sprites de personajes (placeholders)
    ├── maps/                   # Fondos de mapas
    └── ui/                     # Elementos de interfaz
```

---

## 🎮 Componentes Principales

### 1. **Global Script (Autoload)**
**Propósito:** Mantener datos entre escenas

**Variables:**
- `player1_character: int` - ID del personaje de P1
- `player2_character: int` - ID del personaje de P2
- `selected_map: int` - ID del mapa seleccionado
- `player1_lives: int = 3` - Vidas restantes de P1
- `player2_lives: int = 3` - Vidas restantes de P2
- `winner: int = 0` - Quién ganó (1 o 2)

**Funciones:**
- `reset_game()` - Reinicia todas las variables
- `player_lost_life(player_id)` - Resta una vida
- `check_game_over()` - Verifica si hay ganador

---

### 2. **Menú Principal**

**Elementos:**
- Título del juego
- Botón "Jugar" → Cambia a `character_select.tscn`
- Botón "Salir" → Cierra el juego con `get_tree().quit()`

**Diseño temporal:**
- Fondo de color sólido
- Botones con `ColorRect` o `Button` básico
- Labels con fuente grande

---

### 3. **Selección de Personajes**

**Elementos:**
- Título: "Selecciona tu personaje"
- Panel para Jugador 1 (izquierda)
- Panel para Jugador 2 (derecha)
- 2 opciones de personajes por jugador
- Botón "Continuar" (activo cuando ambos eligieron)

**Personajes placeholder:**
- **Personaje 1:** Cuadrado rojo
- **Personaje 2:** Círculo azul

**Controles:**
- P1: W/S para navegar, Espacio para seleccionar
- P2: Flechas arriba/abajo, Enter para seleccionar

**Función:**
```gdscript
func _on_continue_pressed():
    Global.player1_character = selected_p1
    Global.player2_character = selected_p2
    get_tree().change_scene_to_file("res://scenes/map_select.tscn")
```

---

### 4. **Selección de Mapa**

**Elementos:**
- Título: "Selecciona el mapa"
- Vista previa del mapa (imagen placeholder)
- Nombre del mapa: "Arena Clásica"
- Botón "Comenzar Partida"

**Función:**
```gdscript
func _on_start_pressed():
    Global.selected_map = 0  # Solo hay 1 mapa por ahora
    get_tree().change_scene_to_file("res://scenes/game.tscn")
```

---

### 5. **Escena de Juego (game.tscn)**

#### **A. Jugadores**

**Nodo:** `CharacterBody2D` (nombre: Player1, Player2)

**Propiedades:**
- HP actual: 100
- HP máximo: 100
- Velocidad: 300 px/s
- ID del jugador: 1 o 2
- Área de golpe: `Area2D` (hijo del jugador)

**Controles:**
- **Jugador 1:** WASD (movimiento), Espacio (golpear)
- **Jugador 2:** Flechas (movimiento), Enter (golpear)

**Mecánicas:**
- Movimiento en 8 direcciones
- Animación de golpe (0.2s de duración)
- Knockback al recibir daño
- Invulnerabilidad temporal (0.5s) tras recibir daño
- Al llegar a 0 HP: pierde una vida y respawnea

**Posiciones de spawn:**
- P1: Vector2(200, 300)
- P2: Vector2(800, 300)

---

#### **B. Bola**

**Nodo:** `CharacterBody2D` con física personalizada

**Propiedades:**
- Velocidad actual: comienza en 200 px/s
- Dirección: Vector2 aleatorio normalizado
- Velocidad máxima: 1500 px/s
- Incremento por golpe: +50 px/s
- Daño base: 25 HP (puede escalar con velocidad)

**Comportamiento:**
- Se mueve en línea recta
- Rebota al chocar con paredes (refleja dirección)
- Al golpear a un jugador:
  - Causa daño
  - Aplica knockback
  - Sigue su trayectoria
- Desaparece cuando un jugador llega a 0 HP
- Reaparece en el centro cuando el jugador respawnea

**Detección de golpe del jugador:**
```gdscript
# En ball.gd
func hit_by_player(player_id):
    velocity = velocity.normalized() * (velocity.length() + SPEED_INCREMENT)
    velocity = velocity.clamped(MAX_SPEED)
    # Cambiar dirección según posición del jugador
```

---

#### **C. HUD (Interfaz)**

**Elementos:**
- Barra de vida P1 (arriba izquierda)
- Barra de vida P2 (arriba derecha)
- Contador de vidas P1: ❤️ x3
- Contador de vidas P2: ❤️ x3
- Velocidad de la bola (centro superior)

**Actualización:**
- Conectar señales desde `GameManager`
- Actualizar barras con `set_value()`
- Cambiar color de HP según porcentaje:
  - Verde: > 60%
  - Amarillo: 30-60%
  - Rojo: < 30%

---

#### **D. Game Manager**

**Nodo:** `Node` (hijo de game.tscn)

**Responsabilidades:**
- Inicializar jugadores según selección
- Crear y gestionar la bola
- Detectar colisiones bola-jugador
- Gestionar respawns
- Detectar condición de victoria
- Cambiar a pantalla de victoria

**Señales:**
```gdscript
signal player_damaged(player_id, hp_remaining)
signal player_defeated(player_id)
signal ball_speed_changed(new_speed)
signal game_over(winner_id)
```

**Lógica de respawn:**
```gdscript
func respawn_player(player_id):
    var player = get_node("Player" + str(player_id))
    player.hp = MAX_HP
    player.position = SPAWN_POSITIONS[player_id]
    player.invulnerable = true
    
    # Esperar 1 segundo antes de hacer spawn de la bola
    await get_tree().create_timer(1.0).timeout
    spawn_ball()
```

---

### 6. **Pantalla de Victoria**

**Elementos:**
- Texto grande: "¡JUGADOR [X] GANA!"
- Estadísticas opcionales:
  - Velocidad máxima alcanzada
  - Golpes totales
- Botón "Volver al Menú"

**Función:**
```gdscript
func _ready():
    winner_label.text = "¡JUGADOR " + str(Global.winner) + " GANA!"

func _on_menu_pressed():
    Global.reset_game()
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

---

## ⚙️ Especificaciones Técnicas

### **Configuración de Colisiones**

| Layer | Nombre | Usado por |
|-------|--------|-----------|
| 1 | Players | CharacterBody2D de jugadores |
| 2 | Ball | CharacterBody2D de la bola |
| 3 | Walls | StaticBody2D de límites del mapa |
| 4 | HitAreas | Area2D para detectar golpes |

### **Constantes del Juego**

```gdscript
# En global.gd o game_manager.gd
const MAX_HP = 100
const MAX_LIVES = 3
const PLAYER_SPEED = 300
const INITIAL_BALL_SPEED = 200
const BALL_SPEED_INCREMENT = 50
const MAX_BALL_SPEED = 1500
const BASE_DAMAGE = 25
const KNOCKBACK_FORCE = 400
const INVULNERABILITY_TIME = 0.5
const HIT_ANIMATION_TIME = 0.2
```

### **Tamaño de Ventana**

```gdscript
# En project.godot (Project Settings)
[display]
window/size/viewport_width = 1280
window/size/viewport_height = 720
window/stretch/mode = "canvas_items"
```

---

## 📅 Fases de Implementación

### **Fase 1: Fundamentos (1-2 horas)**
1. ✅ Crear estructura de carpetas
2. ✅ Configurar `global.gd` como Autoload
3. ✅ Crear menú principal funcional
4. ✅ Implementar navegación entre escenas

**Entregable:** Menú que cambia a pantalla vacía de selección

---

### **Fase 2: Selección (1 hora)**
5. ✅ Pantalla de selección de personajes
   - UI con opciones
   - Sistema de input para ambos jugadores
   - Guardar selección en Global
6. ✅ Pantalla de selección de mapa
   - Mostrar el único mapa
   - Transición a game scene

**Entregable:** Flujo completo desde menú hasta escena de juego vacía

---

### **Fase 3: Jugabilidad Core (3-4 horas)**
7. ✅ Crear jugadores con movimiento
   - CharacterBody2D con sprite placeholder
   - Input mapping (WASD y Flechas)
   - Movimiento suave
8. ✅ Crear bola con física
   - Movimiento constante
   - Rebotes en paredes
   - Colisiones básicas
9. ✅ Sistema de golpeo
   - Area2D para detectar golpe
   - Cambiar dirección/velocidad de bola
   - Animación de golpe
10. ✅ Sistema de daño y vida
    - Detección bola-jugador
    - Restar HP
    - Mostrar HP en consola

**Entregable:** Juego jugable básico sin sistema de vidas

---

### **Fase 4: Sistema de Vidas (2 horas)**
11. ✅ Implementar knockout y respawn
    - Detectar HP <= 0
    - Restar vida en Global
    - Respawnear jugador en posición inicial
    - Respawnear bola en centro
12. ✅ Detección de victoria
    - Verificar vidas restantes
    - Identificar ganador
    - Cambiar a victory_screen

**Entregable:** Juego completo sin UI visual

---

### **Fase 5: UI y Pulido (2-3 horas)**
13. ✅ HUD funcional
    - Barras de vida visuales
    - Contador de vidas con íconos
    - Indicador de velocidad de bola
14. ✅ Pantalla de victoria
    - Mostrar ganador
    - Estadísticas opcionales
    - Botón de volver al menú
15. ✅ Transiciones y detalles
    - Fade in/out entre escenas
    - Sonido placeholder (opcional)
    - Partículas al golpear (opcional)

**Entregable:** Primera versión jugable completa

---

## 🎨 Placeholders Visuales

### **Jugadores**
- Personaje 1: Cuadrado rojo (64x64 px) con `ColorRect`
- Personaje 2: Círculo azul (64x64 px) - usar `Polygon2D` o sprite circular

### **Bola**
- Círculo blanco (32x32 px)
- Puede cambiar de color según velocidad (opcional):
  - Blanco: < 400
  - Amarillo: 400-800
  - Naranja: 800-1200
  - Rojo: > 1200

### **Mapa**
- Fondo: Degradado azul oscuro a negro
- Paredes: Líneas blancas o `ColorRect` gris
- Dimensiones: 1200x600 px (área jugable)

### **UI**
- Botones: `Button` de Godot con tema por defecto
- Barras de vida: `ProgressBar` con colores personalizados
- Texto: Fuente por defecto, tamaño 32-48 para títulos

---

## 🔧 Configuración del Proyecto

### **Autoload (Project Settings → Autoload)**
```
Name: Global
Path: res://scripts/global.gd
```

### **Input Map (Project Settings → Input Map)**

| Acción | Jugador 1 | Jugador 2 |
|--------|-----------|-----------|
| p1_up | W | - |
| p1_down | S | - |
| p1_left | A | - |
| p1_right | D | - |
| p1_hit | Space | - |
| p2_up | - | Arrow Up |
| p2_down | - | Arrow Down |
| p2_left | - | Arrow Left |
| p2_right | - | Arrow Right |
| p2_hit | - | Enter |

---

## 📝 Notas de Desarrollo

### **Prioridades**
1. ✅ Funcionalidad primero, estética después
2. ✅ Usar placeholders simples (ColorRect, Label)
3. ✅ Código modular y comentado
4. ✅ Facilitar reemplazo de assets después

### **Para Futuras Versiones**
- [ ] Sprites animados de personajes
- [ ] Música y efectos de sonido
- [ ] Más personajes y mapas
- [ ] Power-ups o habilidades especiales
- [ ] Partículas y efectos visuales
- [ ] Menú de pausa
- [ ] Replays o estadísticas detalladas
- [ ] Modo torneo (mejor de 3/5)

### **Testing**
- ✅ Probar cada fase antes de avanzar
- ✅ Verificar colisiones y física de bola
- ✅ Balancear velocidad y daño
- ✅ Asegurar que todos los botones funcionen
- ✅ Testear con ambos jugadores simultáneamente

---

## 🚀 Próximos Pasos

1. **Crear estructura de carpetas** en el proyecto
2. **Implementar `global.gd`** con variables base
3. **Desarrollar menú principal** simple pero funcional
4. **Seguir las fases** en orden secuencial
5. **Testear frecuentemente** cada componente

---

## 📞 Recursos de Godot

- [Documentación oficial de Godot 4](https://docs.godotengine.org/en/stable/)
- [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)
- [Signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)
- [Input handling](https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html)

---

**Versión del documento:** 1.0  
**Fecha:** 2 de diciembre de 2025  
**Engine:** Godot 4.5
