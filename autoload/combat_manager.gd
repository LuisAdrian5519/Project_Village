extends Node

# enum = lista de nombres para valores fijos (por dentro son 0, 1, 2)
enum State { EXPLORE, PLAYER_TURN, ENEMY_TURN }

# Aviso que este script manda cuando cambia el estado
signal state_changed(new_state: State)

var current_state: State = State.EXPLORE

func start_combat() -> void:
	if current_state != State.EXPLORE:
		return  # ya hay combate, ignora
	_set_state(State.PLAYER_TURN)

func end_combat() -> void:
	_set_state(State.EXPLORE)

func _set_state(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	print("Estado: ", State.keys()[new_state])

# TEMPORAL: Esc termina el combate
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and current_state != State.EXPLORE:
		end_combat()
