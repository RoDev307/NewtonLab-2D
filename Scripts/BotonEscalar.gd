extends Button

# Parámetros configurables en el inspector
@export var escala_hover: Vector2 = Vector2(1.08, 1.08) # Crece un 8%
@export var tiempo_animacion: float = 0.15             # Segundos que tarda

var escala_original: Vector2 = Vector2.ONE
var tween: Tween

func _ready() -> void:
	# Asegurar que el pivote se calcule en el centro por si cambia de tamaño
	pivot_offset = size / 2.0
	escala_original = scale
	
	# Conectar las señales del mouse integradas en todos los botones de Godot
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_animar_escala(escala_hover)

func _on_mouse_exited() -> void:
	_animar_escala(escala_original)

func _animar_escala(objetivo: Vector2) -> void:
	# Matar el tween anterior si ya se estaba reproduciendo para evitar tirones
	if tween:
		tween.kill()
	
	# Crear una animación interpolada suave (Tween)
	tween = create_tween()
	# Transición tipo OUT_QUAD / TRANS_SINE para un movimiento natural y "elástico"
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Animar la propiedad "scale" del botón desde su estado actual hasta el objetivo
	tween.tween_property(self, "scale", objetivo, tiempo_animacion)
