extends CharacterBody2D
# La nave NO tiene propulsores: solo se mueve por el RETROCESO al disparar.

const MASA_NAVE: float = 5.0
const VELOCIDAD_MAXIMA: float = 700.0
const RESTITUCION: float = 0.8   # 1 = choque perfectamente elástico

# Objetos que se pueden lanzar: masa (kg), velocidad de salida, tamaño y color
const TIPOS = [
	{"nombre": "Ligero", "masa": 1.0, "velocidad": 900.0, "escala": 0.7, "color": Color(0.5, 1.0, 1.0)},
	{"nombre": "Pesado", "masa": 5.0, "velocidad": 500.0, "escala": 1.8, "color": Color(1.0, 0.6, 0.3)},
]

@export var friccion: float = 1.5   # 0 = espacio perfecto (nunca frena solo)

var velocidad_espacial: Vector2 = Vector2.ZERO
var tipo_bala: int = 0
var destello: float = 0.0
var fuerza_flecha: float = 0.0
var escena_bala: PackedScene = preload("res://Escenas/Minijuegos/bala.tscn")

func _ready() -> void:
	add_to_group("jugador")

func _physics_process(delta: float) -> void:
	velocity = velocidad_espacial
	move_and_slide()

	# Choque con una roca (inmóvil): la nave rebota, perdiendo un poco de energía
	for i in range(get_slide_collision_count()):
		var normal := get_slide_collision(i).get_normal()
		if velocidad_espacial.dot(normal) < 0.0:
			velocidad_espacial = velocidad_espacial.bounce(normal) * RESTITUCION

	# Sin disparos no hay fuerza: la nave solo se va frenando
	velocidad_espacial = velocidad_espacial.lerp(Vector2.ZERO, friccion * delta)

	# La nave apunta al mouse (el triángulo apunta hacia +X)
	look_at(get_global_mouse_position())

	# Límites de la pantalla: rebota en los bordes
	var pantalla := get_viewport_rect().size
	if global_position.x < 0.0 or global_position.x > pantalla.x:
		velocidad_espacial.x = -velocidad_espacial.x
	if global_position.y < 0.0 or global_position.y > pantalla.y:
		velocidad_espacial.y = -velocidad_espacial.y
	global_position = global_position.clamp(Vector2.ZERO, pantalla)

	# Las flechas de acción/reacción se desvanecen
	if destello > 0.0:
		destello = maxf(0.0, destello - delta)
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		disparar_hacia((get_global_mouse_position() - global_position).normalized())
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			tipo_bala = 0
		elif event.keycode == KEY_2:
			tipo_bala = 1

func disparar_hacia(direccion: Vector2) -> void:
	if direccion == Vector2.ZERO:
		return
	var tipo: Dictionary = TIPOS[tipo_bala]

	# --- REPRODUCIR SONIDO DE DISPARO ---
	if get_tree().current_scene.has_method("reproducir_sfx"):
		get_tree().current_scene.reproducir_sfx("disparo")

	# ACCIÓN: el objeto sale hacia "direccion"
	var bala = escena_bala.instantiate()
	bala.direccion_bala = direccion
	bala.velocidad = tipo["velocidad"]
	bala.scale = Vector2.ONE * tipo["escala"]
	bala.modulate = tipo["color"]
	bala.position = global_position + direccion * 30.0
	get_tree().current_scene.add_child(bala)

	# REACCIÓN (3ª ley): momento del objeto = momento de la nave, en sentido opuesto
	var impulso: float = tipo["masa"] * tipo["velocidad"] / MASA_NAVE
	velocidad_espacial -= direccion * impulso
	velocidad_espacial = velocidad_espacial.limit_length(VELOCIDAD_MAXIMA)

	destello = 0.3
	fuerza_flecha = impulso
	queue_redraw()

# Flechas: naranja = acción (F), celeste = reacción (-F)
func _draw() -> void:
	if destello <= 0.0:
		return
	var a := destello / 0.3
	var largo := 15.0 + fuerza_flecha * 0.08
	_flecha(Vector2(24, 0), Vector2(24 + largo, 0), Color(1.0, 0.6, 0.2, a))
	_flecha(Vector2(-16, 0), Vector2(-16 - largo, 0), Color(0.4, 0.9, 1.0, a))

func _flecha(desde: Vector2, hasta: Vector2, col: Color) -> void:
	draw_line(desde, hasta, col, 4.0)
	var d := (hasta - desde).normalized()
	var n := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([hasta + d * 9.0, hasta + n * 6.0, hasta - n * 6.0]), col)
