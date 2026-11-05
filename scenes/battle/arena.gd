extends Node2D

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

var attack_id: int = 0

func _ready() -> void:
	visible = false
	size = get_viewport_rect().size   # el área cubre toda la pantalla
	position = size / 2.0             # y se centra
	queue_redraw()                    # vuelve a ejecutar _draw() con el nuevo tamaño
	CombatManager.state_changed.connect(_on_state_changed)

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
		_fire_burst(attack_id)
		
func _fire_burst(this_attack_id: int) -> void:
	for shot in range(3):
		if this_attack_id != attack_id:
			return
			
		_fire_sav()
		
		# Solo esperamos si todavía queda otro disparo.
		if shot < 2:
			await get_tree().create_timer(shot_interval).timeout
			
	await _burrow_and_relocate(this_attack_id)
		
func _fire_sav() -> void:
	var projectile = SAV_SCENE.instantiate()
	
	projectile.position = enemy_sprite.position
	projectile.direction = (soul.position - enemy_sprite.position).normalized()
	
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
			candidate.distance_to(enemy_sprite.position) >= 120.0
		)

		if far_from_player and far_from_previous:
			return candidate

	# Si no encontramos un sitio válido, conservamos el anterior.
	return enemy_sprite.position
	
