extends Node2D

@export var max_enemigos: int = 6
var escena_enemigo: PackedScene = preload("res://Escenas/Minijuegos/enemigo.tscn")

func _on_timer_timeout() -> void:
	var eliminados: int = get_tree().current_scene.eliminados

	# Dificultad suave: aparecen más seguido y caben más enemigos mientras más eliminas
	$Timer.wait_time = maxf(0.6, randf_range(1.0, 3.0) - eliminados * 0.05)
	var maximo := mini(max_enemigos + int(eliminados / 5.0), 16)
	if get_tree().get_nodes_in_group("enemigos").size() < maximo:
		spawnear_enemigo()

func spawnear_enemigo() -> void:
	var pantalla := get_viewport_rect().size
	var margen := 40.0
	var pos: Vector2

	# Aparece en un borde AL AZAR, fuera de la pantalla (nunca encima de la nave)
	match randi() % 4:
		0: pos = Vector2(randf_range(0.0, pantalla.x), -margen)
		1: pos = Vector2(randf_range(0.0, pantalla.x), pantalla.y + margen)
		2: pos = Vector2(-margen, randf_range(0.0, pantalla.y))
		_: pos = Vector2(pantalla.x + margen, randf_range(0.0, pantalla.y))

	var enemigo = escena_enemigo.instantiate()
	enemigo.position = pos
	get_tree().current_scene.add_child(enemigo)
