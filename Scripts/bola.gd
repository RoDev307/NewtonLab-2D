extends RigidBody2D

signal golpe_realizado

const INICIO := Vector2(180, 365)
const RADIO: float = 22.0
const GRAVEDAD: float = 980.0

const POTENCIA_MINIMA: float = 120.0
const POTENCIA_MAXIMA: float = 1200.0
const VELOCIDAD_CARGA: float = 440.0
const DURACION_GOLPE: float = 0.16

const PISTA := Rect2(8, 132, 1136, 468)
const MADERA := Rect2(384, 132, 384, 468)
const ARENA := Rect2(768, 132, 376, 468)

var activa: bool = false
var lanzada: bool = false
var cargando: bool = false
var golpeando: bool = false
var reiniciar_pendiente: bool = false

var potencia: float = POTENCIA_MINIMA
var tiempo_movimiento: float = 0.0
var progreso_golpe: float = 0.0
var direccion: Vector2 = Vector2.RIGHT


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	global_position = INICIO
	gravity_scale = 0.0
	mass = 1.0
	lock_rotation = true

	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp = 0.0

	z_index = 5

	var colision := get_node_or_null("CollisionShape2D") as CollisionShape2D

	if colision != null:
		var circulo := CircleShape2D.new()
		circulo.radius = RADIO
		colision.shape = circulo


func comenzar_intento() -> void:
	activa = true
	lanzada = false
	cargando = false
	golpeando = false

	potencia = POTENCIA_MINIMA
	tiempo_movimiento = 0.0
	progreso_golpe = 0.0
	direccion = Vector2.RIGHT

	reiniciar_pendiente = true
	sleeping = false
	queue_redraw()


func _process(delta: float) -> void:
	if not activa:
		return

	if not lanzada and not golpeando and not reiniciar_pendiente:
		var hacia_cursor: Vector2 = (
			get_global_mouse_position() - global_position
		)

		if hacia_cursor.length() > 1.0:
			direccion = hacia_cursor.normalized()

	if cargando:
		potencia = minf(
			potencia + VELOCIDAD_CARGA * delta,
			POTENCIA_MAXIMA
		)

	if golpeando:
		progreso_golpe += delta

		if progreso_golpe >= DURACION_GOLPE:
			golpeando = false
			lanzada = true
			tiempo_movimiento = 0.0
			apply_central_impulse(direccion * potencia)
			golpe_realizado.emit()

	queue_redraw()


func _physics_process(delta: float) -> void:
	if lanzada:
		tiempo_movimiento += delta


func _unhandled_input(event: InputEvent) -> void:
	if not activa or reiniciar_pendiente:
		return

	if lanzada or golpeando:
		return

	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:
			if PISTA.has_point(get_global_mouse_position()):
				cargando = true
				potencia = POTENCIA_MINIMA

		elif cargando:
			cargando = false
			golpeando = true
			progreso_golpe = 0.0


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if reiniciar_pendiente:
		state.transform = Transform2D(0.0, INICIO)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		reiniciar_pendiente = false
		return

	if not activa:
		return

	var coeficiente: float = obtener_coeficiente(
		state.transform.origin
	)

	state.linear_velocity = state.linear_velocity.move_toward(
		Vector2.ZERO,
		coeficiente * GRAVEDAD * state.step
	)


func obtener_coeficiente(posicion: Vector2) -> float:
	if MADERA.has_point(posicion):
		return 0.4

	if ARENA.has_point(posicion):
		return 0.8

	return 0.0


func obtener_superficie() -> String:
	if Rect2(8, 132, 376, 468).has_point(global_position):
		return "HIELO"

	if MADERA.has_point(global_position):
		return "MADERA"

	if ARENA.has_point(global_position):
		return "ARENA"

	return "FUERA"


func _draw() -> void:
	if activa and not lanzada:
		dibujar_taco()

	# Sombra de la bola.
	draw_ellipse_shadow()

	# Cuerpo con apariencia de volumen.
	draw_circle(Vector2.ZERO, 24.0, Color("#28223F"))
	draw_circle(Vector2.ZERO, 20.5, Color("#BCCADA"))
	draw_circle(Vector2(-3, -4), 17.0, Color("#E8EFF5"))
	draw_circle(Vector2(-6, -7), 10.0, Color("#FFFFFF"))

	# Flecha de velocidad.
	var rapidez: float = linear_velocity.length()

	if rapidez > 10.0:
		var rumbo: Vector2 = linear_velocity.normalized()

		dibujar_flecha(
			Vector2(0, -48),
			rumbo,
			Color("#20C565"),
			65.0
		)

		# Rozamiento en sentido opuesto al movimiento.
		if obtener_coeficiente(global_position) > 0.0:
			dibujar_flecha(
				Vector2(0, 58),
				-rumbo,
				Color("#F64F4F"),
				60.0
			)

		# Estela detrás de la bola.
		for i in range(3):
			var desplazamiento := Vector2(0, float(i - 1) * 12.0)
			var inicio: Vector2 = (
				-rumbo * (40.0 + i * 6.0) + desplazamiento
			)
			var fin: Vector2 = inicio - rumbo * 40.0

			draw_line(
				inicio,
				fin,
				Color(1, 1, 1, 0.6),
				3.0,
				true
			)


func draw_ellipse_shadow() -> void:
	draw_set_transform(
		Vector2(3, 26),
		0.0,
		Vector2(1.0, 0.3)
	)
	draw_circle(Vector2.ZERO, 23.0, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO)


func dibujar_flecha(
	inicio: Vector2,
	rumbo: Vector2,
	color: Color,
	largo: float
) -> void:
	var punta: Vector2 = inicio + rumbo * largo
	var lateral := Vector2(-rumbo.y, rumbo.x)

	draw_line(
		inicio,
		punta - rumbo * 15.0,
		color,
		7.0,
		true
	)

	draw_colored_polygon(
		PackedVector2Array([
			punta,
			punta - rumbo * 24.0 + lateral * 15.0,
			punta - rumbo * 24.0 - lateral * 15.0
		]),
		color
	)


func dibujar_taco() -> void:
	var separacion: float = 35.0
	var porcentaje: float = potencia / POTENCIA_MAXIMA

	if cargando:
		separacion += porcentaje * 65.0

	if golpeando:
		var avance: float = clampf(
			progreso_golpe / DURACION_GOLPE,
			0.0,
			1.0
		)

		separacion = lerpf(
			35.0 + porcentaje * 65.0,
			RADIO,
			avance
		)

	# Guía de apuntado.
	if not golpeando:
		for i in range(6):
			draw_circle(
				direccion * (40.0 + i * 22.0),
				2.0,
				Color(1, 1, 1, 0.65)
			)

	# Dibujar el taco en coordenadas giradas.
	draw_set_transform(Vector2.ZERO, direccion.angle())

	var punta := Vector2(-separacion, 0)
	var extremo := Vector2(-separacion - 155.0, 0)

	draw_line(
		extremo + Vector2(0, 4),
		punta + Vector2(0, 4),
		Color(0, 0, 0, 0.25),
		16.0,
		true
	)

	draw_line(extremo, punta, Color("#27203E"), 16.0, true)
	draw_line(extremo, punta, Color("#CC934A"), 9.0, true)

	draw_line(
		extremo + Vector2(0, -2),
		punta + Vector2(0, -2),
		Color("#FFE0A2"),
		3.0,
		true
	)

	# Mango morado.
	draw_line(
		extremo,
		extremo + Vector2(55, 0),
		Color("#5C438B"),
		9.0,
		true
	)

	# Punta turquesa.
	draw_line(
		punta - Vector2(10, 0),
		punta,
		Color("#36C8DF"),
		12.0,
		true
	)

	draw_set_transform(Vector2.ZERO)
