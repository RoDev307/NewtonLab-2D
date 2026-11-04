extends Area2D

var velocidad: float = 900.0
var direccion_bala: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# La conexión se hace por código para que funcione en TODAS las balas que se crean
	body_entered.connect(_on_body_entered)
	rotation = direccion_bala.angle()

func _physics_process(delta: float) -> void:
	global_position += direccion_bala * velocidad * delta

	# Borrar la bala cuando sale de la pantalla
	if not get_viewport_rect().grow(100.0).has_point(global_position):
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemigos"):
		get_tree().current_scene.sumar_eliminado()
		body.morir()
		queue_free()
