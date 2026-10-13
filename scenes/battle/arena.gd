extends Node2D

@export var size := Vector2(300, 200)

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

# La caja se ve durante todo el combate; el Soul solo en ENEMY_TURN
func _on_state_changed(new_state: int) -> void:
	visible = (new_state != CombatManager.State.EXPLORE)
