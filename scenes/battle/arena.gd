extends Node2D

const MIN_RELOCATION_DISTANCE: float = 120.0
const SPAWN_DEBUG_SHADER: Shader = preload("res://scenes/battle/spawn_debug.gdshader")

const SAV_SCENE: PackedScene = preload(
	"res://scenes/battle/SavProjectile.tscn"
)

@export var size := Vector2(300, 200)
@export var shot_interval: float = 0.5

@onready var soul: Area2D = $Soul
@onready var enemy_sprite: Node2D = $CarnivorousPlant

# Enemy variables
@export var down_time: float = 0.5
@export var spawn_margin: float = 80.0
@export var safe_distance: float = 180.0
@export var emerge_delay: float = 0.3

# Debug variables
@export var show_spawn_debug: bool = true

var attack_id: int = 0
var _spawn_debug: ColorRect
var _spawn_debug_material: ShaderMaterial

func _ready() -> void:
	visible = false
	size = get_viewport_rect().size   # el área cubre toda la pantalla
	position = size / 2.0             # y se centra
	queue_redraw()                    # vuelve a ejecutar _draw() con el nuevo tamaño
	_create_spawn_debug()
	CombatManager.state_changed.connect(_on_state_changed)

func _create_spawn_debug() -> void:
	_spawn_debug_material = ShaderMaterial.new()
	_spawn_debug_material.shader = SPAWN_DEBUG_SHADER
	_spawn_debug = ColorRect.new()
	_spawn_debug.name = "SpawnDebug"
	_spawn_debug.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spawn_debug.material = _spawn_debug_material
	add_child(_spawn_debug)
	# Sobre el fondo de Arena, debajo del personaje, la planta y los proyectiles.
	move_child(_spawn_debug, 0)
	_update_spawn_debug()

func _process(_delta: float) -> void:
	_spawn_debug.visible = show_spawn_debug
	if visible and show_spawn_debug:
		_update_spawn_debug()

func _update_spawn_debug() -> void:
	_spawn_debug.position = -size / 2.0
	_spawn_debug.size = size
	_spawn_debug.visible = show_spawn_debug
	_spawn_debug_material.set_shader_parameter("arena_size", size)
	_spawn_debug_material.set_shader_parameter("spawn_margin", spawn_margin)
	_spawn_debug_material.set_shader_parameter("player_position", soul.position)
	_spawn_debug_material.set_shader_parameter("plant_position", enemy_sprite.position)
	_spawn_debug_material.set_shader_parameter("safe_distance", safe_distance)
	_spawn_debug_material.set_shader_parameter("relocation_distance", MIN_RELOCATION_DISTANCE)

# _draw() se ejecuta una vez para dibujar este nodo con código.
# Dibujamos la caja centrada en el origen del Arena.
func _draw() -> void:
	var r := Rect2(-size / 2.0, size)
	draw_rect(r, Color.BLACK)
	draw_rect(r, Color.WHITE, false, 4.0)  # false = solo el borde

# La caja se ve durante todo el combate
func _on_state_changed(new_state: int) -> void:
	visible = (new_state != CombatManager.State.EXPLORE)
	
	# Cada cambio de estado invalida cualquier ráfaga anterior.
	attack_id += 1
	enemy_sprite.show()
	
	if new_state == CombatManager.State.ENEMY_TURN:
		_run_enemy_turn(attack_id)
	else:
		for projectile in get_tree().get_nodes_in_group("enemy_projectiles"):
			projectile.queue_free()
		
func _fire_burst(this_attack_id: int) -> void:
	for shot in range(3):
		if this_attack_id != attack_id:
			return
			
		_fire_sav()
		
		# Solo esperamos si todavía queda otro disparo.
		if shot < 2:
			await get_tree().create_timer(shot_interval).timeout
		
func _fire_sav() -> void:
	var projectile = SAV_SCENE.instantiate()
	
	projectile.position = enemy_sprite.position
	projectile.direction = (soul.position - enemy_sprite.position).normalized()
	
	projectile.arena_bounds = Rect2(-size / 2.0, size)
	
	projectile.add_to_group("enemy_projectiles")
	add_child(projectile)
	
func _burrow_and_relocate(this_attack_id: int) -> void:
	if this_attack_id != attack_id:
		return

	enemy_sprite.hide()

	await get_tree().create_timer(down_time).timeout

	if this_attack_id != attack_id:
		return

	enemy_sprite.position = _pick_spawn_position()
	enemy_sprite.show()
	
func _pick_spawn_position() -> Vector2:
	var half: Vector2 = size / 2.0 - Vector2.ONE * spawn_margin

	for attempt in range(20):
		var candidate := Vector2(
			randf_range(-half.x, half.x),
			randf_range(-half.y, half.y)
		)

		var far_from_player := (
			candidate.distance_to(soul.position) >= safe_distance
		)
		var far_from_previous := (
			candidate.distance_to(enemy_sprite.position) >= MIN_RELOCATION_DISTANCE
		)

		if far_from_player and far_from_previous:
			return candidate

	# Si no encontramos un sitio válido, conservamos el anterior.
	return enemy_sprite.position
	
func _run_enemy_turn(this_attack_id: int) -> void:
	for burst in range(3):
		if this_attack_id != attack_id:
			return

		await _fire_burst(this_attack_id)

		if this_attack_id != attack_id:
			return

		# Después de la tercera ráfaga, permanece donde está.
		if burst < 2:
			await _burrow_and_relocate(this_attack_id)

			if this_attack_id != attack_id:
				return

			await get_tree().create_timer(emerge_delay).timeout

	while not get_tree().get_nodes_in_group("enemy_projectiles").is_empty():
		if this_attack_id != attack_id:
			return

		await get_tree().process_frame

	if this_attack_id != attack_id:
		return

	CombatManager.finish_enemy_turn()
	
