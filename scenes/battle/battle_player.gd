extends Area2D

const START_POS := Vector2(-350, 0)  # lado izquierdo de la pantalla de batalla

@export var speed: float = 220.0
@export var margin: float = 24.0  # distancia mínima al borde


@onready var arena = get_parent()

func _ready() -> void:
	position = START_POS
	CombatManager.state_changed.connect(_on_state_changed)

func _physics_process(delta: float) -> void:
	# Solo te mueves en el turno enemigo (esquivando)
	if CombatManager.current_state != CombatManager.State.ENEMY_TURN:
		return
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	position += dir.normalized() * speed * delta
	var half: Vector2 = arena.size / 2.0 - Vector2(margin, margin)
	position = position.clamp(-half, half)

func _on_state_changed(new_state: int) -> void:
	# Al terminar el combate, deja listo al player para la próxima pelea
	if new_state == CombatManager.State.EXPLORE:
		position = START_POS
