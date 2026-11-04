extends Node2D
# Rocas grandes y SÓLIDAS: la nave rebota en ellas y los enemigos las rodean.
# Capa de física 3 (valor 4) = rocas.

@export var cantidad: int = 6
@export var escala_min: float = 2.0
@export var escala_max: float = 3.4

const TEXTURAS: Array[Texture2D] = [
	preload("res://Assets/Escenarios/Espacial/PNG/Default/meteor_large.png"),
	preload("res://Assets/Escenarios/Espacial/PNG/Default/meteor_detailedLarge.png"),
]
const RADIO_BASE: float = 22.5      # radio útil del sprite (px) con escala 1
const ZONA_NAVE: float = 120.0      # espacio libre alrededor de donde aparece la nave
const HUECO_MIN: float = 100.0      # separación mínima entre rocas (para que pase la nave)
const BORDE: float = 20.0

var sprites: Array[Sprite2D] = []
var giro: Array[float] = []

func _ready() -> void:
	var pantalla := get_viewport_rect().size
	# Zona libre alrededor de donde nace la nave (su posición real en la escena)
	var nave := get_parent().get_node_or_null("naveJugador") as Node2D
	var centro: Vector2 = nave.position if nave else pantalla / 2.0
	var posiciones: Array[Vector2] = []
	var radios: Array[float] = []
	var intentos := 0

	while posiciones.size() < cantidad and intentos < 500:
		intentos += 1
		var escala := randf_range(escala_min, escala_max)
		var radio := RADIO_BASE * escala
		var pos := Vector2(
			randf_range(radio + BORDE, pantalla.x - radio - BORDE),
			randf_range(radio + BORDE, pantalla.y - radio - BORDE))

		if pos.distance_to(centro) < radio + ZONA_NAVE:
			continue
		var libre := true
		for k in range(posiciones.size()):
			if pos.distance_to(posiciones[k]) < radio + radios[k] + HUECO_MIN:
				libre = false
				break
		if not libre:
			continue

		posiciones.append(pos)
		radios.append(radio)
		_crear_roca(pos, escala, radio)

func _crear_roca(pos: Vector2, escala: float, radio: float) -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.position = pos
	cuerpo.collision_layer = 4      # capa 3: rocas
	cuerpo.collision_mask = 0
	cuerpo.add_to_group("rocas")

	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = radio
	forma.shape = circulo
	cuerpo.add_child(forma)

	var sprite := Sprite2D.new()
	sprite.texture = TEXTURAS.pick_random()
	sprite.rotation = randf() * TAU
	sprite.scale = Vector2.ONE * escala
	var tono := randf_range(0.5, 0.7)
	sprite.modulate = Color(tono * 1.1, tono, tono * 0.9, 1.0)
	cuerpo.add_child(sprite)

	add_child(cuerpo)
	sprites.append(sprite)
	giro.append(randf_range(-0.25, 0.25))

func _process(delta: float) -> void:
	# Solo gira el dibujo (despacio); el círculo de colisión no cambia
	for i in range(sprites.size()):
		sprites[i].rotation += giro[i] * delta
