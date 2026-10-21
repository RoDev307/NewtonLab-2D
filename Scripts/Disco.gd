extends RigidBody2D
class_name DiscoInercia

const PPM: float = 100.0
const RADIO: float = 24.0

var destino_reset: Vector2 = Vector2.ZERO
var pendiente_reset: bool = false

func _ready() -> void:
	# Asegurar gravedad cero para plano cenital
	gravity_scale = 0.0
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if pendiente_reset:
		state.transform.origin = destino_reset
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		pendiente_reset = false

func reiniciar_en(posicion: Vector2) -> void:
	destino_reset = posicion
	pendiente_reset = true

func configurar_friccion(amortiguamiento: float) -> void:
	linear_damp = amortiguamiento

func aplicar_impulso_inicial(fuerza_impulso: Vector2) -> void:
	apply_central_impulse(fuerza_impulso)

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIO, Color(0.95, 0.95, 0.95))
	draw_arc(Vector2.ZERO, RADIO, 0, TAU, 32, Color(0.2, 0.2, 0.2), 2.0)

	if linear_velocity.length() > 5.0:
		var dir_vector: Vector2 = linear_velocity * 0.25
		draw_line(Vector2.ZERO, dir_vector, Color(0.95, 0.75, 0.1), 3.0)
		draw_circle(dir_vector, 4.0, Color(0.9, 0.2, 0.2))

func _process(_delta: float) -> void:
	queue_redraw()
