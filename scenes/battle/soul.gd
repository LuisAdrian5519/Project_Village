extends Area2D

@export var speed: float = 180.0
@export var margin: float = 10.0  # para que el corazón no se pegue al borde

# @onready = esta variable se llena cuando el nodo ya está listo en el árbol
# (el padre ya existe). Es el Arena, que va a contener al Soul.
@onready var arena = get_parent()

func _ready() -> void:
	visible = false
	CombatManager.state_changed.connect(_on_state_changed)

func _physics_process(delta: float) -> void:
	if not visible:
		return
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	position += dir.normalized() * speed * delta
	# Clamp = "no te salgas de esta caja". position es local al Arena.
	var half: Vector2 = arena.size / 2.0 - Vector2(margin, margin)
	position = position.clamp(-half, half)

func _on_state_changed(new_state: int) -> void:
	visible = (new_state == CombatManager.State.ENEMY_TURN)
	if visible:
		position = Vector2.ZERO  # empieza en el centro de la caja
