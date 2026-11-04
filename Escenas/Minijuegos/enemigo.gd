extends CharacterBody2D

const TEXTURAS: Array[Texture2D] = [
	preload("res://Assets/Escenarios/Espacial/PNG/Default/enemy_A.png"),
	preload("res://Assets/Escenarios/Espacial/PNG/Default/enemy_B.png"),
	preload("res://Assets/Escenarios/Espacial/PNG/Default/enemy_D.png"),
]

var velocidad: float = 120.0
var jugador: Node2D = null
var lado: float = 1.0 if randf() < 0.5 else -1.0   # hacia qué lado rodea una roca
var normal_roca: Vector2 = Vector2.ZERO            # roca con la que chocó el frame anterior

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemigos")
	sprite.texture = TEXTURAS.pick_random()
	jugador = get_tree().get_first_node_in_group("jugador")

	# Velocidad distinta en cada enemigo, y un poco más rápidos mientras más eliminas
	var eliminados = get_tree().current_scene.get("eliminados")
	if eliminados == null:
		eliminados = 0
	velocidad = randf_range(90.0, 160.0) + minf(eliminados * 3.0, 80.0)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(jugador):
		return

	# Perseguir a la nave
	var dir := (jugador.global_position - global_position).normalized()

	# Si una roca le cierra el paso, avanza por el borde de la roca (la rodea)
	if normal_roca != Vector2.ZERO and dir.dot(normal_roca) < 0.0:
		var tangente := dir.slide(normal_roca)
		if tangente.length() < 0.2:
			tangente = normal_roca.orthogonal() * lado
		dir = tangente.normalized()
	normal_roca = Vector2.ZERO

	velocity = dir * velocidad
	move_and_slide()
	sprite.rotation = velocity.angle() + PI / 2.0   # el sprite apunta hacia arriba

	for i in range(get_slide_collision_count()):
		var choque := get_slide_collision(i)
		var otro := choque.get_collider()
		if otro.is_in_group("jugador"):
			# Si toca a la nave, pierdes
			get_tree().current_scene.perder()
			return
		elif otro.is_in_group("rocas"):
			normal_roca = choque.get_normal()

# Explosión sencilla: 8 cuadritos que salen disparados y se desvanecen
func morir() -> void:
	remove_from_group("enemigos")
	set_physics_process(false)
	for i in range(8):
		var trozo := ColorRect.new()
		trozo.size = Vector2(7, 7)
		trozo.position = position - Vector2(3.5, 3.5)
		trozo.color = Color(1.0, randf_range(0.3, 0.7), 0.2)
		get_tree().current_scene.add_child(trozo)

		var destino := trozo.position + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 90.0)
		var tween := trozo.create_tween()
		tween.set_parallel(true)
		tween.tween_property(trozo, "position", destino, 0.4)
		tween.tween_property(trozo, "modulate:a", 0.0, 0.4)
		tween.chain().tween_callback(trozo.queue_free)
	queue_free()
