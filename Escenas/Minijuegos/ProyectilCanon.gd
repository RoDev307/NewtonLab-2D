extends RigidBody2D

signal medicion_lista(resultado: Dictionary)
@export var fuerza: float = 7000.0
const DURACION: float = 0.1
var direccion: Vector2 = Vector2(1, -0.5).normalized()
var angulo: float = rad_to_deg(atan(0.5))
var lanzado: bool = false
var pasos_restantes: int = 0
var pasos_totales: int = 0
var velocidad_anterior := Vector2.ZERO
var muestras: Array[float] = []
var duracion_real: float = 0

func _ready() -> void:
	freeze = true

func lanzar() -> void:
	if lanzado:
		return
	lanzado = true
	pasos_totales = maxi(2, roundi(DURACION * Engine.physics_ticks_per_second))
	pasos_restantes = pasos_totales
	constant_force = direccion * fuerza
	velocidad_anterior = linear_velocity
	freeze = false

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if pasos_restantes <= 0:
		return
	# Se mide Δv/Δt y se resta la contribución de la gravedad.
	# Se omite la primera muestra para evitar la transición del cuerpo congelado.
	if pasos_restantes < pasos_totales:
		var aceleracion := (state.linear_velocity - velocidad_anterior) / state.step - state.total_gravity
		muestras.append(aceleracion.dot(direccion))
	velocidad_anterior = state.linear_velocity
	duracion_real += state.step
	pasos_restantes -= 1
	if pasos_restantes == 0:
		constant_force = Vector2.ZERO
		var medida: float = 0
		for muestra in muestras:
			medida += muestra
		medida /= maxf(muestras.size(), 1)
		medicion_lista.emit.call_deferred({"fuerza": fuerza, "masa": mass, "teorica": fuerza / mass, "medida": medida, "duracion": duracion_real, "angulo": angulo})
