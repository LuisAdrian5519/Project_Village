extends Area2D

@export var speed: float = 300
@export var direction: Vector2 = Vector2.RIGHT

@onready var lifetime: Timer = $Lifetime

func _ready() -> void:
	# connect() no ejecuta la eliminación ni espera los cinco segundos. Solo registra qué hacer cuando el Timer emita timeout.
	# On timeout, ejecuta _on_lifetime_timeout: una función propia que elimina el proyectil
	lifetime.timeout.connect(_on_lifetime_timeout)
	lifetime.start()
	
func _physics_process(delta: float) -> void:
	position += direction.normalized() * speed * delta
	
func _on_lifetime_timeout() -> void:
	queue_free()
	
