extends CharacterBody2D

@export var speed: float = 150.0

func _physics_process(delta: float) -> void:
	if CombatManager.current_state != CombatManager.State.EXPLORE:
		return  # en combate el personaje no se mueve directamente
		
	var input_dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	velocity = input_dir.normalized() * speed
	move_and_slide()
