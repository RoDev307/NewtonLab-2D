extends Node2D

# ==================================================
# CONFIGURACIÓN
# ==================================================

const TAMANO := Vector2(1152, 750)
const PISTA := Rect2(8, 132, 1136, 468)
const DIANA := Vector2(960, 365)

const RADIO_DIANA: float = 100.0
const VIDAS_MAXIMAS: int = 5

# Conversión interna para los cálculos físicos.
const PIXELES_POR_METRO: float = 100.0
const GRAVEDAD: float = 9.8

const TINTA := Color("#24183D")
const MORADO := Color("#4D2B87")
const OSCURO := Color("#1D1236")
const AMARILLO := Color("#FFD83D")
const TURQUESA := Color("#37C6DD")
const BLANCO := Color("#FFFFFF")

@onready var bola = $Bola

var fuente: Font
var fuente_cuerpo: Font

var capa: CanvasLayer
var controles: Control
var modal: Control
var tarjeta: Panel

var vidas_boton: Button
var cuenta_texto: Label

var musica: AudioStreamPlayer
var efectos: AudioStreamPlayer

var golpe_audio: AudioStreamWAV
var victoria_audio: AudioStreamWAV
var derrota_audio: AudioStreamWAV

var volumen_musica: float = 30.0
var volumen_efectos: float = 65.0

var pantalla: String = "menu"
var vidas: int = VIDAS_MAXIMAS
var intentos: int = 0
var victorias: int = 0

var gano_ultimo: bool = false
var reloj: float = 0.0
var reinicio_restante: float = -1.0

var cache_texturas: Dictionary = {}


# ==================================================
# INICIO Y ACTUALIZACIÓN
# ==================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	fuente = cargar_fuente(
		"res://assets/fonts/LilitaOne-Regular.ttf",
		PackedStringArray(["Lilita One", "Arial Black", "Verdana"]),
		800
	)

	fuente_cuerpo = cargar_fuente(
		"res://assets/fonts/Nunito-ExtraBold.ttf",
		PackedStringArray(["Nunito", "Trebuchet MS", "Arial"]),
		800
	)

	crear_audio()
	crear_interfaz()

	bola.golpe_realizado.connect(al_golpear)
	mostrar_menu()


func _process(delta: float) -> void:
	reloj += delta
	queue_redraw()

	if pantalla == "resultado" and reinicio_restante >= 0.0:
		reinicio_restante = maxf(
			reinicio_restante - delta,
			0.0
		)

		if is_instance_valid(cuenta_texto):
			cuenta_texto.text = (
				"Nueva partida en %d..."
				% int(ceil(reinicio_restante))
			)

		if reinicio_restante <= 0.0:
			iniciar_partida()

		return

	if pantalla != "juego":
		return

	actualizar_vidas()

	if not bola.lanzada:
		return

	if bola.tiempo_movimiento < 0.2:
		return

	if not PISTA.has_point(bola.global_position):
		mostrar_resultado(false, true)
		return

	if bola.linear_velocity.length() < 1.0:
		var distancia: float = bola.global_position.distance_to(
			DIANA
		)

		mostrar_resultado(
			distancia <= RADIO_DIANA,
			false
		)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	if event.keycode == KEY_ESCAPE:
		if pantalla == "juego":
			mostrar_pausa()
		elif pantalla == "pausa" or pantalla == "info":
			continuar()
		elif pantalla == "ayuda":
			mostrar_menu()

		get_viewport().set_input_as_handled()


func cargar_fuente(
	ruta: String,
	alternativas: PackedStringArray,
	peso: int
) -> Font:
	if ResourceLoader.exists(ruta):
		var archivo: Font = load(ruta) as Font

		if archivo != null:
			return archivo

	var sistema := SystemFont.new()
	sistema.font_names = alternativas
	sistema.font_weight = peso
	return sistema


# ==================================================
# CONTROLES Y ESTILOS
# ==================================================

func estilo(
	fondo: Color,
	borde: Color = TINTA,
	radio: int = 16,
	grosor: int = 4
) -> StyleBoxFlat:
	var recurso := StyleBoxFlat.new()
	recurso.bg_color = fondo
	recurso.border_color = borde
	recurso.set_corner_radius_all(radio)
	recurso.set_border_width_all(grosor)
	return recurso


func etiqueta(
	padre: Node,
	contenido: String,
	posicion: Vector2,
	tamano: Vector2,
	tamano_fuente: int = 23,
	color: Color = BLANCO
) -> Label:
	var elemento := Label.new()
	elemento.position = posicion
	elemento.size = tamano
	elemento.text = contenido

	elemento.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elemento.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	elemento.mouse_filter = Control.MOUSE_FILTER_IGNORE

	elemento.add_theme_font_override("font", fuente_cuerpo)
	elemento.add_theme_font_size_override("font_size", tamano_fuente)
	elemento.add_theme_color_override("font_color", color)
	elemento.add_theme_color_override("font_outline_color", TINTA)
	elemento.add_theme_constant_override("outline_size", 3)

	padre.add_child(elemento)
	return elemento


func boton(
	padre: Node,
	contenido: String,
	posicion: Vector2,
	tamano: Vector2,
	accion: Callable,
	color: Color = AMARILLO,
	tamano_fuente: int = 22
) -> Button:
	var elemento := Button.new()
	elemento.position = posicion
	elemento.size = tamano
	elemento.text = contenido
	elemento.pivot_offset = tamano / 2.0

	elemento.focus_mode = Control.FOCUS_NONE
	elemento.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	elemento.add_theme_font_override("font", fuente)
	elemento.add_theme_font_size_override("font_size", tamano_fuente)

	for estado in [
		"font_color",
		"font_hover_color",
		"font_pressed_color"
	]:
		elemento.add_theme_color_override(
			estado,
			Color("#1B1040")
		)

	elemento.add_theme_stylebox_override(
		"normal",
		estilo_boton_relieve(tamano, color, 0)
	)
	elemento.add_theme_stylebox_override(
		"hover",
		estilo_boton_relieve(tamano, color, 1)
	)
	elemento.add_theme_stylebox_override(
		"pressed",
		estilo_boton_relieve(tamano, color, 2)
	)

	elemento.mouse_entered.connect(
		animar_boton.bind(elemento, true)
	)
	elemento.mouse_exited.connect(
		animar_boton.bind(elemento, false)
	)
	elemento.pressed.connect(accion)

	padre.add_child(elemento)
	return elemento


func animar_boton(elemento: Button, encima: bool) -> void:
	if elemento.has_meta("hover_tween"):
		var anterior: Tween = elemento.get_meta(
			"hover_tween"
		) as Tween

		if anterior != null and anterior.is_valid():
			anterior.kill()

	var animacion := elemento.create_tween()
	elemento.set_meta("hover_tween", animacion)

	animacion.tween_property(
		elemento,
		"scale",
		Vector2(1.025, 1.025) if encima else Vector2.ONE,
		0.12
	)


func crear_interfaz() -> void:
	capa = CanvasLayer.new()
	capa.layer = 20
	add_child(capa)

	controles = Control.new()
	controles.size = TAMANO
	controles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(controles)

	boton(
		controles,
		"¡Detén la bola dentro de la diana!",
		Vector2(345, 25),
		Vector2(420, 50),
		info_objetivo,
		AMARILLO,
		20
	)

	vidas_boton = boton(
		controles,
		"♥ 5/5",
		Vector2(930, 28),
		Vector2(110, 46),
		info_vidas,
		Color("#FFB7CF"),
		22
	)

	boton(
		controles,
		"Ⅱ",
		Vector2(1060, 23),
		Vector2(60, 58),
		mostrar_pausa,
		TURQUESA,
		28
	)

	boton(
		controles,
		"○ HIELO    μ 0.0",
		Vector2(82, 111),
		Vector2(220, 48),
		info_hielo,
		Color("#C8F1F7"),
		21
	)

	boton(
		controles,
		"□ MADERA    μ 0.4",
		Vector2(463, 111),
		Vector2(220, 48),
		info_madera,
		Color("#EAB477"),
		20
	)

	boton(
		controles,
		"△ ARENA    μ 0.8",
		Vector2(846, 111),
		Vector2(220, 48),
		info_arena,
		Color("#FFE5A1"),
		21
	)

	boton(
		controles,
		"?",
		Vector2(160, 665),
		Vector2(40, 40),
		info_velocidad,
		AMARILLO,
		25
	)

	modal = Control.new()
	modal.size = TAMANO
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	capa.add_child(modal)


func actualizar_vidas() -> void:
	vidas_boton.text = "♥ %d/%d" % [
		vidas,
		VIDAS_MAXIMAS
	]


# ==================================================
# VENTANAS Y MENÚS
# ==================================================

func preparar_ventana(
	titulo: String,
	tamano: Vector2 = Vector2(580, 555)
) -> void:
	for hijo in modal.get_children():
		modal.remove_child(hijo)
		hijo.queue_free()

	cuenta_texto = null
	modal.show()

	var sombra := ColorRect.new()
	sombra.size = TAMANO

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform sampler2D pantalla :
	hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec3 fondo = textureLod(
		pantalla,
		SCREEN_UV,
		1.8
	).rgb;

	vec2 p = UV - vec2(0.5, 0.45);
	p.x *= 1.35;

	float distancia = clamp(length(p) * 1.6, 0.0, 1.0);

	vec3 tinte = mix(
		vec3(0.157, 0.059, 0.392),
		vec3(0.031, 0.008, 0.110),
		distancia
	);

	float oscuridad = mix(0.45, 0.84, distancia);

	COLOR = vec4(
		mix(fondo, tinte, oscuridad),
		1.0
	);
}
"""

	var material_fondo := ShaderMaterial.new()
	material_fondo.shader = shader
	sombra.material = material_fondo
	modal.add_child(sombra)

	tarjeta = Panel.new()
	tarjeta.position = (TAMANO - tamano) / 2.0
	tarjeta.size = tamano
	tarjeta.pivot_offset = tamano / 2.0
	tarjeta.clip_contents = false

	var estilo_panel := StyleBoxTexture.new()
	estilo_panel.texture = textura_ventana(tamano)
	estilo_panel.texture_margin_left = 34
	estilo_panel.texture_margin_right = 34
	estilo_panel.texture_margin_top = 34
	estilo_panel.texture_margin_bottom = 34

	tarjeta.add_theme_stylebox_override("panel", estilo_panel)
	modal.add_child(tarjeta)

	var ancho_cinta: float = minf(tamano.x + 60.0, 760.0)

	var cinta := TextureRect.new()
	cinta.texture = textura_cinta(ancho_cinta)
	cinta.position = Vector2(
		(tamano.x - ancho_cinta) / 2.0,
		-34
	)
	cinta.size = Vector2(ancho_cinta, 92)
	cinta.custom_minimum_size = Vector2(ancho_cinta, 92)
	cinta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cinta.stretch_mode = TextureRect.STRETCH_SCALE
	cinta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tarjeta.add_child(cinta)

	var tamano_titulo: int = 33

	if titulo.length() > 23:
		tamano_titulo = 27

	var titulo_etiqueta := Label.new()
	titulo_etiqueta.position = Vector2(0, 5)
	titulo_etiqueta.size = Vector2(ancho_cinta, 64)
	titulo_etiqueta.custom_minimum_size = Vector2(ancho_cinta, 64)
	titulo_etiqueta.text = titulo
	titulo_etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo_etiqueta.autowrap_mode = TextServer.AUTOWRAP_OFF
	titulo_etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titulo_etiqueta.add_theme_font_override("font", fuente)
	titulo_etiqueta.add_theme_font_size_override("font_size", tamano_titulo)
	titulo_etiqueta.add_theme_color_override("font_color", BLANCO)
	titulo_etiqueta.add_theme_color_override(
		"font_outline_color",
		Color("#5A2C00")
	)
	titulo_etiqueta.add_theme_constant_override("outline_size", 5)
	cinta.add_child(titulo_etiqueta)

	tarjeta.scale = Vector2(0.90, 0.90)
	tarjeta.modulate.a = 0.0

	var animacion := tarjeta.create_tween()
	animacion.set_parallel(true)

	animacion.tween_property(
		tarjeta,
		"scale",
		Vector2.ONE,
		0.32
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	animacion.tween_property(
		tarjeta,
		"modulate:a",
		1.0,
		0.2
	)


func mostrar_menu() -> void:
	reinicio_restante = -1.0
	pantalla = "menu"
	get_tree().paused = true

	bola.activa = false
	bola.hide()
	controles.hide()

	preparar_ventana("NEWTONLAB 2D", Vector2(580, 390))

	etiqueta(
		tarjeta,
		"¡Tienes cinco vidas para demostrar tu puntería!",
		Vector2(35, 105),
		Vector2(510, 75),
		25
	)

	boton(
		tarjeta,
		"Jugar",
		Vector2(45, 210),
		Vector2(490, 58),
		iniciar_partida,
		TURQUESA,
		25
	)

	boton(
		tarjeta,
		"Cómo jugar",
		Vector2(45, 290),
		Vector2(490, 52),
		mostrar_ayuda,
		Color("#BEEBFF"),
		22
	)


func mostrar_ayuda() -> void:
	pantalla = "ayuda"
	preparar_ventana("¡ASÍ SE JUEGA!")

	etiqueta(
		tarjeta,
		"Apunta con el mouse y mantén clic en la pista.\n\n"
		+ "Suelta para golpear con el taco.\n\n"
		+ "Detén toda la bola dentro de la diana.\n\n"
		+ "Cada derrota cuesta una vida.\n\n"
		+ "Sin vidas, comienza una partida nueva.\n\n"
		+ "Esc: pausar.",
		Vector2(40, 100),
		Vector2(500, 345),
		21
	)

	boton(
		tarjeta,
		"¡Entendido!",
		Vector2(45, 465),
		Vector2(490, 52),
		mostrar_menu,
		TURQUESA,
		24
	)


func iniciar_partida() -> void:
	vidas = VIDAS_MAXIMAS
	intentos = 0
	victorias = 0
	reinicio_restante = -1.0
	nuevo_intento()


func nuevo_intento() -> void:
	if vidas <= 0:
		iniciar_partida()
		return

	reinicio_restante = -1.0
	cuenta_texto = null

	pantalla = "juego"
	intentos += 1
	gano_ultimo = false

	modal.hide()
	controles.show()

	get_tree().paused = false
	bola.show()
	bola.comenzar_intento()

	actualizar_vidas()


func mostrar_pausa() -> void:
	if pantalla != "juego":
		return

	bola.cargando = false
	pantalla = "pausa"
	get_tree().paused = true

	preparar_ventana("PAUSA", Vector2(580, 340))

	boton(
		tarjeta,
		"Continuar",
		Vector2(45, 145),
		Vector2(490, 55),
		continuar,
		TURQUESA,
		25
	)

	boton(
		tarjeta,
		"Menú principal",
		Vector2(45, 230),
		Vector2(490, 52),
		mostrar_menu,
		Color("#D1B3F5"),
		24
	)


func continuar() -> void:
	modal.hide()
	pantalla = "juego"
	get_tree().paused = false


# ==================================================
# RESULTADOS Y DATOS DE FÍSICA
# ==================================================

func mostrar_resultado(gano: bool, fuera: bool) -> void:
	if pantalla != "juego":
		return

	pantalla = "resultado"
	gano_ultimo = gano
	bola.activa = false
	get_tree().paused = true

	# Distancia usada internamente para asignar estrellas.
	var distancia_px: float = bola.global_position.distance_to(DIANA)

	var obtenidas: int = 0
	var titulo: String = "¡OTRA OPORTUNIDAD!"
	var detalle: String = "Ajusta la potencia y vuelve a intentarlo."
	var frase: String = "¡La ciencia también se aprende probando!"

	if gano:
		victorias += 1
		obtenidas = 1

		if distancia_px <= 40.0:
			obtenidas = 2

		if distancia_px <= 18.0:
			obtenidas = 3

		titulo = "¡EXCELENTE GOLPE!"
		detalle = "¡La bola quedó dentro de la diana!"
		frase = "¡Observa cómo el rozamiento cambió tu movimiento!"

		reproducir(victoria_audio)
	else:
		vidas = maxi(vidas - 1, 0)

		if fuera:
			detalle = "La bola salió de la pista. Revisa tu dirección."

		if vidas == 0:
			titulo = "¡SIN VIDAS!"
			detalle = "Comenzaremos una partida nueva."
			frase = "¡Cada experimento te enseña algo nuevo!"

		reproducir(derrota_audio)

	actualizar_vidas()

	# Cálculos físicos.
	var masa: float = bola.mass
	var impulso: float = bola.potencia / PIXELES_POR_METRO
	var velocidad_inicial: float = impulso / masa

	var velocidad_actual: float = (
		bola.linear_velocity.length() / PIXELES_POR_METRO
	)

	var energia_inicial: float = (
		0.5 * masa * velocidad_inicial * velocidad_inicial
	)

	var energia_actual: float = (
		0.5 * masa * velocidad_actual * velocidad_actual
	)

	preparar_ventana(titulo, Vector2(1000, 650))

	# Científico animado.
	var cientifico := CientificoAnimado.new()
	cientifico.gano = gano
	cientifico.position = Vector2(25, 90)
	cientifico.size = Vector2(225, 265)
	tarjeta.add_child(cientifico)

	# Globo del científico.
	var globo := Panel.new()
	globo.position = Vector2(25, 365)
	globo.size = Vector2(225, 85)

	var estilo_globo := estilo(
		BLANCO,
		Color("#D8C8F5"),
		15,
		2
	)
	estilo_globo.shadow_color = Color(0, 0, 0, 0.25)
	estilo_globo.shadow_size = 1
	estilo_globo.shadow_offset = Vector2(0, 4)

	globo.add_theme_stylebox_override("panel", estilo_globo)
	tarjeta.add_child(globo)

	var punta := Polygon2D.new()
	punta.position = Vector2(112, 0)
	punta.polygon = PackedVector2Array([
		Vector2(-9, 0),
		Vector2(0, -11),
		Vector2(9, 0)
	])
	punta.color = BLANCO
	globo.add_child(punta)

	var frase_etiqueta := etiqueta(
		globo,
		frase,
		Vector2(12, 10),
		Vector2(201, 67),
		17,
		Color("#1B1040")
	)
	frase_etiqueta.add_theme_constant_override("outline_size", 0)

	# Estrellas únicamente en los resultados.
	for i in range(3):
		var tamano_estrella: float = 54.0
		var y: float = 77.0

		if i == 1:
			tamano_estrella = 65.0
			y = 67.0

		poner_simbolo(
			tarjeta,
			"estrella",
			i < obtenidas,
			Vector2(
				515.0 + i * 78.0
				- (tamano_estrella - 54.0) / 2.0,
				y
			),
			Vector2(tamano_estrella, tamano_estrella),
			float(i) * 0.12
		)

	etiqueta(
		tarjeta,
		detalle,
		Vector2(280, 145),
		Vector2(680, 45),
		21
	)

	# Vidas.
	for i in range(VIDAS_MAXIMAS):
		poner_simbolo(
			tarjeta,
			"corazon",
			i < vidas,
			Vector2(45.0 + i * 38.0, 470),
			Vector2(31, 31),
			float(i) * 0.08
		)

	etiqueta(
		tarjeta,
		"Vidas: %d / %d\nIntentos: %d · Victorias: %d"
		% [vidas, VIDAS_MAXIMAS, intentos, victorias],
		Vector2(20, 510),
		Vector2(240, 55),
		18,
		Color("#FFE566")
	)

	# Datos físicos.
	tarjeta_fisica(
		"MASA",
		"%.2f kg" % masa,
		"Cantidad de materia",
		Vector2(285, 205)
	)

	tarjeta_fisica(
		"VELOCIDAD INICIAL",
		"%.2f m/s" % velocidad_inicial,
		"Justo después del golpe",
		Vector2(510, 205)
	)

	tarjeta_fisica(
		"VELOCIDAD ACTUAL",
		"%.2f m/s" % velocidad_actual,
		"Al terminar este tiro",
		Vector2(735, 205)
	)

	tarjeta_fisica(
		"IMPULSO DEL GOLPE",
		"%.2f N·s" % impulso,
		"J = m · Δv",
		Vector2(285, 290)
	)

	tarjeta_fisica(
		"ENERGÍA INICIAL",
		"%.2f J" % energia_inicial,
		"Ec = ½ · m · v²",
		Vector2(510, 290)
	)

	tarjeta_fisica(
		"ENERGÍA ACTUAL",
		"%.2f J" % energia_actual,
		"Energía del movimiento",
		Vector2(735, 290)
	)

	tabla_rozamiento(masa)

	# Sin texto de escala, distancia ni fórmulas de fuerza/freno.

	if vidas > 0:
		if gano:
			boton(
				tarjeta,
				"Continuar",
				Vector2(260, 580),
				Vector2(480, 50),
				nuevo_intento,
				TURQUESA,
				24
			)
		else:
			boton(
				tarjeta,
				"Intentar de nuevo",
				Vector2(260, 580),
				Vector2(480, 50),
				nuevo_intento,
				AMARILLO,
				24
			)
	else:
		reinicio_restante = 5.0

		cuenta_texto = etiqueta(
			tarjeta,
			"Nueva partida en 5...",
			Vector2(20, 588),
			Vector2(240, 35),
			18,
			AMARILLO
		)

		boton(
			tarjeta,
			"Nueva partida",
			Vector2(260, 580),
			Vector2(480, 50),
			iniciar_partida,
			AMARILLO,
			24
		)


func tarjeta_fisica(
	titulo: String,
	valor: String,
	explicacion: String,
	posicion: Vector2
) -> void:
	var fondo := Panel.new()
	fondo.position = posicion
	fondo.size = Vector2(215, 76)

	fondo.add_theme_stylebox_override(
		"panel",
		estilo(
			Color("#281650"),
			Color("#7353AA"),
			14,
			2
		)
	)
	tarjeta.add_child(fondo)

	var nombre := etiqueta(
		fondo,
		titulo,
		Vector2(8, 7),
		Vector2(199, 18),
		12,
		Color("#CDB8FF")
	)
	nombre.add_theme_constant_override("outline_size", 0)

	var numero := etiqueta(
		fondo,
		valor,
		Vector2(8, 24),
		Vector2(199, 32),
		25,
		Color("#FFE566")
	)
	numero.add_theme_font_override("font", fuente)

	var descripcion := etiqueta(
		fondo,
		explicacion,
		Vector2(8, 57),
		Vector2(199, 17),
		11,
		Color("#D9F8FF")
	)
	descripcion.add_theme_constant_override("outline_size", 0)


func tabla_rozamiento(masa: float) -> void:
	var fondo := Panel.new()
	fondo.position = Vector2(285, 395)
	fondo.size = Vector2(665, 122)

	fondo.add_theme_stylebox_override(
		"panel",
		estilo(
			Color("#281650"),
			Color("#7353AA"),
			14,
			2
		)
	)
	tarjeta.add_child(fondo)

	etiqueta(
		fondo,
		"ROZAMIENTO DURANTE EL DESLIZAMIENTO",
		Vector2(10, 5),
		Vector2(645, 23),
		15,
		AMARILLO
	)

	var encabezados: Array[String] = [
		"Superficie",
		"μ",
		"Fuerza (N)",
		"Freno (m/s²)"
	]

	var posiciones_x: Array[float] = [
		10.0,
		170.0,
		300.0,
		470.0
	]

	var anchos: Array[float] = [
		150.0,
		100.0,
		160.0,
		180.0
	]

	for columna in range(4):
		var cabecera := etiqueta(
			fondo,
			encabezados[columna],
			Vector2(posiciones_x[columna], 32),
			Vector2(anchos[columna], 20),
			13,
			Color("#CDB8FF")
		)
		cabecera.add_theme_constant_override("outline_size", 0)

	var superficies: Array[String] = [
		"Hielo",
		"Madera",
		"Arena"
	]

	var coeficientes: Array[float] = [
		bola.obtener_coeficiente(Vector2(180, 365)),
		bola.obtener_coeficiente(Vector2(500, 365)),
		bola.obtener_coeficiente(Vector2(900, 365))
	]

	for fila in range(3):
		var mu: float = coeficientes[fila]
		var fuerza: float = mu * masa * GRAVEDAD
		var desaceleracion: float = mu * GRAVEDAD

		var valores: Array[String] = [
			superficies[fila],
			"%.1f" % mu,
			"%.2f" % fuerza,
			"%.2f" % desaceleracion
		]

		for columna in range(4):
			var dato := etiqueta(
				fondo,
				valores[columna],
				Vector2(
					posiciones_x[columna],
					54.0 + fila * 20.0
				),
				Vector2(anchos[columna], 20),
				14,
				BLANCO
			)
			dato.add_theme_constant_override("outline_size", 0)


# ==================================================
# INFORMACIÓN EDUCATIVA
# ==================================================

func informacion(titulo: String, contenido: String) -> void:
	if pantalla != "juego":
		return

	bola.cargando = false
	pantalla = "info"
	get_tree().paused = true

	preparar_ventana(titulo)

	etiqueta(
		tarjeta,
		contenido,
		Vector2(40, 125),
		Vector2(500, 280),
		24
	)

	boton(
		tarjeta,
		"¡A seguir jugando!",
		Vector2(45, 455),
		Vector2(490, 55),
		continuar,
		TURQUESA,
		24
	)


func info_objetivo() -> void:
	informacion(
		"TU OBJETIVO",
		"Detén toda la bola dentro de la diana.\n\n"
		+ "Cuanto más cerca quede del centro, "
		+ "más estrellas consigues en los resultados.\n\n"
		+ "Cada derrota cuesta una vida."
	)


func info_vidas() -> void:
	informacion(
		"TUS CINCO VIDAS",
		"Comienzas con cinco vidas.\n\n"
		+ "Pierdes una si la bola queda fuera de la diana "
		+ "o sale de la pista.\n\n"
		+ "Ganar conserva tus vidas."
	)


func info_hielo() -> void:
	informacion(
		"HIELO · μ 0.0",
		"Este hielo es ideal: no tiene rozamiento.\n\n"
		+ "Después del golpe, la bola conserva su velocidad "
		+ "mientras permanezca sobre esta superficie.\n\n"
		+ "Fuerza horizontal neta: 0 N."
	)


func info_madera() -> void:
	informacion(
		"MADERA · μ 0.4",
		"La madera produce rozamiento.\n\n"
		+ "Mientras la bola desliza, una fuerza "
		+ "se opone a su movimiento.\n\n"
		+ "Por eso disminuye su velocidad."
	)


func info_arena() -> void:
	informacion(
		"ARENA · μ 0.8",
		"La arena frena más que la madera.\n\n"
		+ "Su coeficiente de rozamiento es mayor.\n\n"
		+ "Necesitas suficiente velocidad para "
		+ "alcanzar el centro de la diana."
	)


func info_velocidad() -> void:
	informacion(
		"VELOCIDAD Y POTENCIA",
		"El velocímetro indica qué tan rápido "
		+ "se mueve la bola.\n\n"
		+ "La barra de potencia controla "
		+ "el impulso del taco.\n\n"
		+ "Más potencia produce mayor velocidad inicial."
	)


func salir() -> void:
	get_tree().paused = false
	if ResourceLoader.exists("res://Escenas/MenuPrincipal.tscn"):
		get_tree().change_scene_to_file("res://Escenas/MenuPrincipal.tscn")
	else:
		get_tree().quit()


# ==================================================
# DIBUJO DEL ESCENARIO
# ==================================================

func letras(
	contenido: String,
	posicion: Vector2,
	tamano: int,
	color: Color = BLANCO,
	contorno: bool = true
) -> void:
	if contorno:
		draw_string_outline(
			fuente,
			posicion,
			contenido,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			tamano,
			4,
			TINTA
		)

	draw_string(
		fuente,
		posicion,
		contenido,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		tamano,
		color
	)


func _draw() -> void:
	if fuente == null:
		return

	draw_rect(Rect2(Vector2.ZERO, TAMANO), OSCURO)

	dibujar_pista()
	dibujar_encabezado()
	dibujar_potencia()
	dibujar_velocimetro()

	if pantalla == "juego" and bola.lanzada:
		var rapidez: float = bola.linear_velocity.length()

		if rapidez > 10.0:
			var posicion: Vector2 = bola.global_position

			letras(
				"VELOCIDAD",
				Vector2(
					clampf(posicion.x - 30.0, 15.0, 1000.0),
					clampf(posicion.y - 66.0, 195.0, 530.0)
				),
				18
			)

			if bola.obtener_coeficiente(posicion) > 0.0:
				letras(
					"FRENA",
					Vector2(
						clampf(posicion.x - 10.0, 15.0, 1050.0),
						clampf(posicion.y + 88.0, 220.0, 580.0)
					),
					18
				)

	if pantalla == "resultado" and gano_ultimo:
		dibujar_confeti()


func dibujar_encabezado() -> void:
	draw_rect(Rect2(0, 0, 1152, 100), MORADO)

	draw_line(
		Vector2(0, 100),
		Vector2(1152, 100),
		Color("#8C61BB"),
		4.0
	)

	for i in range(12):
		draw_circle(
			Vector2(
				40.0 + i * 100.0,
				14.0 + (i % 3) * 20.0
			),
			2.0,
			Color(1, 1, 1, 0.2)
		)




func dibujar_pista() -> void:
	# Hielo.
	for i in range(40):
		var proporcion: float = float(i) / 39.0
		var color: Color = Color("#D4F8FF").lerp(
			Color("#8DC3D3"),
			proporcion
		)
		draw_rect(Rect2(0, 132 + i * 12, 384, 12), color)

	# Madera.
	draw_rect(Rect2(384, 132, 384, 468), Color("#D8A05E"))

	for fila in range(9):
		var y: float = 132.0 + fila * 54.0

		draw_line(
			Vector2(384, y),
			Vector2(768, y),
			Color("#B67C40"),
			3.0
		)

		var division: float = 435.0 + (fila % 3) * 88.0

		draw_line(
			Vector2(division, y),
			Vector2(division, minf(y + 54.0, 600.0)),
			Color("#B67C40"),
			3.0
		)

		draw_circle(
			Vector2(division + 8.0, y + 11.0),
			3.0,
			Color("#A46B37")
		)

	# Arena.
	for i in range(32):
		var proporcion: float = float(i) / 31.0
		var sombra: float = absf(proporcion - 0.5) * 2.0

		var color: Color = Color("#FFE6A2").lerp(
			Color("#C9A56B"),
			sombra * 0.6
		)

		draw_rect(Rect2(768 + i * 12, 132, 12, 468), color)

	ovalo(Vector2(93, 257), Vector2(64, 23), Color("#E8FBFF"))
	ovalo(Vector2(273, 207), Vector2(43, 15), Color("#E8FBFF"))
	ovalo(Vector2(278, 517), Vector2(73, 27), Color("#DFF8FF"))

	draw_polyline(
		PackedVector2Array([
			Vector2(43, 536),
			Vector2(95, 505),
			Vector2(137, 520),
			Vector2(179, 482)
		]),
		Color("#F0FDFF"),
		3.0,
		true
	)

	draw_polyline(
		PackedVector2Array([
			Vector2(263, 175),
			Vector2(294, 207),
			Vector2(276, 236)
		]),
		BLANCO,
		3.0,
		true
	)

	for punto in [
		Vector2(64, 175),
		Vector2(116, 437),
		Vector2(337, 385)
	]:
		draw_line(
			punto - Vector2(7, 0),
			punto + Vector2(7, 0),
			BLANCO,
			2.0
		)
		draw_line(
			punto - Vector2(0, 7),
			punto + Vector2(0, 7),
			BLANCO,
			2.0
		)

	for fila in range(3):
		var puntos := PackedVector2Array()

		for i in range(24):
			puntos.append(
				Vector2(
					785.0 + i * 7.0,
					205.0 + fila * 150.0
					+ sin(i * 0.22) * 10.0
				)
			)

		draw_polyline(
			puntos,
			Color("#D6A34A"),
			4.0,
			true
		)

	for i in range(7):
		ovalo(
			Vector2(
				800.0 + fmod(i * 73.0, 280.0),
				265.0 + fmod(i * 91.0, 285.0)
			),
			Vector2(7, 4),
			Color("#C99743")
		)

	for i in range(10):
		var transparencia: float = (
			0.14 * (1.0 - float(i) / 10.0)
		)

		for x in [384.0, 768.0]:
			draw_rect(
				Rect2(x - 10.0 + i, 132, 1, 468),
				Color(0.12, 0.08, 0.1, transparencia)
			)

	# Diana.
	ovalo(
		DIANA + Vector2(8, 18),
		Vector2(105, 34),
		Color(0.35, 0.22, 0.12, 0.3)
	)

	draw_circle(DIANA, 103.0, TINTA)
	draw_circle(DIANA, 98.0, Color("#FF5299"))
	draw_circle(DIANA, 74.0, TINTA)
	draw_circle(DIANA, 69.0, BLANCO)
	draw_circle(DIANA, 47.0, TINTA)
	draw_circle(DIANA, 42.0, Color("#FF79B4"))
	draw_circle(DIANA, 29.0, TINTA)
	draw_circle(DIANA, 25.0, TURQUESA)
	draw_circle(DIANA, 12.0, TINTA)
	draw_circle(DIANA, 9.0, AMARILLO)

	draw_arc(
		DIANA, 94.0, -2.5, -1.8, 24,
		Color("#FFBBDD"), 6.0, true
	)

	dibujar_cactus(Vector2(1090, 552))

	for y in [100.0, 600.0]:
		draw_rect(Rect2(0, y, 1152, 32), Color("#754122"))
		draw_rect(Rect2(0, y + 5, 1152, 8), Color("#BA7A39"))
		draw_line(Vector2(0, y), Vector2(1152, y), TINTA, 4.0)
		draw_line(
			Vector2(0, y + 31),
			Vector2(1152, y + 31),
			TINTA,
			4.0
		)


func ovalo(
	centro: Vector2,
	radios: Vector2,
	color: Color
) -> void:
	draw_set_transform(centro, 0.0, radios)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO)


func dibujar_cactus(base: Vector2) -> void:
	draw_line(
		base - Vector2(0, 30),
		base + Vector2(0, 14),
		TINTA,
		20.0,
		true
	)

	draw_line(
		base - Vector2(0, 30),
		base + Vector2(0, 14),
		Color("#49AD69"),
		13.0,
		true
	)

	for lado in [-1.0, 1.0]:
		var x: float = lado * 14.0
		var puntos := PackedVector2Array([
			base + Vector2(0, -4),
			base + Vector2(x, -4),
			base + Vector2(x, -24)
		])

		draw_polyline(puntos, TINTA, 12.0, true)
		draw_polyline(puntos, Color("#49AD69"), 7.0, true)


func dibujar_potencia() -> void:
	draw_rect(Rect2(0, 635, 1152, 115), OSCURO)
	letras("POTENCIA", Vector2(332, 662), 23)

	var porcentaje: float = 0.0

	if bola.cargando or bola.golpeando or bola.lanzada:
		porcentaje = bola.potencia / bola.POTENCIA_MAXIMA

	var activos: int = int(ceil(porcentaje * 22.0))

	for i in range(22):
		var color: Color = Color("#403065")

		if i < activos:
			color = Color("#5DE383").lerp(
				AMARILLO,
				float(i) / 21.0
			)

		draw_rect(Rect2(332 + i * 21, 676, 17, 30), color)

	letras(
		"%.0f%%" % (porcentaje * 100.0),
		Vector2(740, 662),
		23,
		AMARILLO,
		false
	)

	draw_style_box(
		estilo(Color(0, 0, 0, 0), BLANCO, 8, 3),
		Rect2(603, 670, 69, 43)
	)

	letras(
		"ZONA IDEAL",
		Vector2(602, 737),
		14,
		Color("#5DE383"),
		false
	)

	letras(
		"APUNTA Y SUELTA",
		Vector2(845, 700),
		22,
		AMARILLO
	)


func dibujar_velocimetro() -> void:
	var centro := Vector2(97, 716)
	var rapidez: float = bola.linear_velocity.length()
	var proporcion: float = clampf(rapidez / 1200.0, 0.0, 1.0)

	draw_arc(
		centro, 58.0, PI, TAU, 48,
		Color("#403065"), 13.0, true
	)

	draw_arc(
		centro, 58.0, PI, PI + PI * 0.62, 40,
		TURQUESA, 13.0, true
	)

	var angulo: float = lerpf(PI, TAU, proporcion)

	draw_line(
		centro,
		centro + Vector2.from_angle(angulo) * 45.0,
		BLANCO,
		5.0,
		true
	)

	draw_circle(centro, 7.0, AMARILLO)

	letras(
		"%.0f px/s" % rapidez,
		Vector2(57, 745),
		16,
		TURQUESA,
		false
	)


func dibujar_confeti() -> void:
	var colores: Array[Color] = [
		AMARILLO,
		TURQUESA,
		Color("#FF73AF"),
		BLANCO
	]

	for i in range(65):
		var posicion := Vector2(
			fmod(float(i * 83), 1152.0),
			fmod(reloj * 100.0 + i * 37.0, 750.0)
		)

		draw_rect(
			Rect2(posicion, Vector2(7, 12)),
			colores[i % colores.size()]
		)


# ==================================================
# TEXTURAS DE LA INTERFAZ
# ==================================================

func textura_svg(codigo: String) -> Texture2D:
	if cache_texturas.has(codigo):
		return cache_texturas[codigo] as Texture2D

	var imagen := Image.new()
	var error: int = imagen.load_svg_from_string(codigo)

	if error != OK:
		push_error("No se pudo generar una textura de la interfaz.")
		return null

	var textura: Texture2D = ImageTexture.create_from_image(imagen)
	cache_texturas[codigo] = textura
	return textura


func estilo_boton_relieve(
	tamano: Vector2,
	color: Color,
	estado: int
) -> StyleBoxTexture:
	var arriba: Color = color.lightened(0.25)
	var medio: Color = color
	var abajo: Color = color.darkened(0.3)

	if color == AMARILLO:
		arriba = Color("#FFE566")
		medio = Color("#FFB62E")
		abajo = Color("#C97A0A")
	elif color == TURQUESA:
		arriba = Color("#6EE7F7")
		medio = Color("#22B6D6")
		abajo = Color("#0F7F9C")

	if estado == 1:
		arriba = arriba.lightened(0.12)
		medio = medio.lightened(0.12)
		abajo = abajo.lightened(0.12)

	if estado == 2:
		arriba = arriba.darkened(0.1)
		medio = medio.darkened(0.1)

	var w: int = int(tamano.x)
	var h: int = int(tamano.y + 8.0)
	var desplazamiento: int = 4 if estado == 2 else 0
	var borde: String = "#FFFFFF" if estado == 1 else "#1A0E3B"

	var codigo: String = """
<svg xmlns="http://www.w3.org/2000/svg"
	width="%d" height="%d">
	<defs>
		<linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
			<stop offset="0" stop-color="#%s"/>
			<stop offset=".6" stop-color="#%s"/>
			<stop offset="1" stop-color="#%s"/>
		</linearGradient>
	</defs>
	<rect x="3" y="9" width="%d" height="%d"
		rx="16" fill="#1A0E3B"/>
	<rect x="3" y="%d" width="%d" height="%d"
		rx="16" fill="url(#g)"
		stroke="%s" stroke-width="3"/>
	<path d="M20 %d H%d"
		stroke="#FFFFFF" stroke-opacity=".55"
		stroke-width="3" stroke-linecap="round"/>
</svg>
""" % [
		w, h,
		arriba.to_html(false),
		medio.to_html(false),
		abajo.to_html(false),
		w - 6, h - 12,
		3 + desplazamiento,
		w - 6, h - 12,
		borde,
		8 + desplazamiento,
		w - 20
	]

	var recurso := StyleBoxTexture.new()
	recurso.texture = textura_svg(codigo)
	recurso.texture_margin_left = 20
	recurso.texture_margin_right = 20
	recurso.texture_margin_top = 12
	recurso.texture_margin_bottom = 16

	recurso.content_margin_left = 6
	recurso.content_margin_right = 6
	recurso.content_margin_top = 0
	recurso.content_margin_bottom = 4
	recurso.expand_margin_bottom = 8

	return recurso


func textura_ventana(tamano: Vector2) -> Texture2D:
	var w: int = int(tamano.x)
	var h: int = int(tamano.y)
	var rayas: String = ""

	for desplazamiento in range(-h, w, 36):
		var x0: float = 30.0 + desplazamiento
		var y0: float = 38.0
		var x1: float = x0 + h - 76.0
		var y1: float = h - 38.0

		if x0 < 30.0:
			y0 += 30.0 - x0
			x0 = 30.0

		if x1 > w - 30.0:
			y1 -= x1 - (w - 30.0)
			x1 = w - 30.0

		if y0 < y1 and x0 < x1:
			rayas += (
				"<path d='M%.1f %.1f L%.1f %.1f' "
				+ "stroke='#FFFFFF' stroke-opacity='.035' "
				+ "stroke-width='14'/>"
			) % [x0, y0, x1, y1]

	var codigo: String = """
<svg xmlns="http://www.w3.org/2000/svg"
	width="%d" height="%d">
	<defs>
		<linearGradient id="panel" x1="0" y1="0" x2="0" y2="1">
			<stop offset="0" stop-color="#6A45C2"/>
			<stop offset="1" stop-color="#3B2279"/>
		</linearGradient>
		<radialGradient id="luz" cx=".5" cy="0" r=".8">
			<stop offset="0" stop-color="#FFFFFF" stop-opacity=".18"/>
			<stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
		</radialGradient>
		<radialGradient id="tornillo" cx=".35" cy=".3" r=".7">
			<stop offset="0" stop-color="#FFFFFF"/>
			<stop offset=".4" stop-color="#D9C6FF"/>
			<stop offset="1" stop-color="#7C5BD0"/>
		</radialGradient>
	</defs>

	<rect x="8" y="17" width="%d" height="%d"
		rx="30" fill="#0B0320"/>

	<rect x="5" y="5" width="%d" height="%d"
		rx="30" fill="#1A0E3B"/>

	<rect x="11" y="10" width="%d" height="%d"
		rx="25" fill="url(#panel)"
		stroke="#B99BFF" stroke-width="4"/>

	<rect x="15" y="14" width="%d" height="%d"
		rx="22" fill="url(#luz)"/>

	%s

	<circle cx="27" cy="28" r="6" fill="url(#tornillo)"/>
	<circle cx="%d" cy="28" r="6" fill="url(#tornillo)"/>
	<circle cx="27" cy="%d" r="6" fill="url(#tornillo)"/>
	<circle cx="%d" cy="%d" r="6" fill="url(#tornillo)"/>
</svg>
""" % [
		w, h,
		w - 16, h - 22,
		w - 10, h - 15,
		w - 22, h - 28,
		w - 30, h - 36,
		rayas,
		w - 27,
		h - 35,
		w - 27, h - 35
	]

	return textura_svg(codigo)


func textura_cinta(ancho: float = 640.0) -> Texture2D:
	var w: float = maxf(ancho, 200.0)
	var rf_x0: float = w - 72.0
	var rf_x1: float = w - 12.0
	var rf_notch: float = w - 27.0
	var rect_x: float = 36.0
	var rect_w: float = w - 72.0
	var hl_x1: float = w - 55.0

	var codigo: String = """<svg xmlns="http://www.w3.org/2000/svg"
	width="%.0f" height="92" viewBox="0 0 %.0f 92">
	<defs>
		<linearGradient id="oro" x1="0" y1="0" x2="0" y2="1">
			<stop offset="0" stop-color="#FFE566"/>
			<stop offset=".55" stop-color="#FFB62E"/>
			<stop offset="1" stop-color="#C97A0A"/>
		</linearGradient>
	</defs>

	<path d="M12 22 H72 V78 H12 L27 50Z"
		fill="#AD650E" stroke="#1A0E3B" stroke-width="4"/>

	<path d="M%.1f 22 H%.1f L%.1f 50 L%.1f 78 H%.1fZ"
		fill="#AD650E" stroke="#1A0E3B" stroke-width="4"/>

	<rect x="%.1f" y="17" width="%.1f" height="63"
		rx="16" fill="#0B0320"/>

	<rect x="%.1f" y="6" width="%.1f" height="63"
		rx="16" fill="url(#oro)"
		stroke="#1A0E3B" stroke-width="4"/>

	<path d="M55 13 H%.1f"
		stroke="#FFF7BC" stroke-width="3"
		stroke-linecap="round"/>
</svg>""" % [
		w, w,
		rf_x0, rf_x1, rf_notch, rf_x1, rf_x0,
		rect_x, rect_w,
		rect_x, rect_w,
		hl_x1
	]

	return textura_svg(codigo)


func textura_simbolo(tipo: String, lleno: bool) -> Texture2D:
	var forma: String
	var color_superior: String
	var color_inferior: String

	if tipo == "estrella":
		forma = (
			"M32 4l8.2 17.4 19 2.3-14 13 "
			+ "3.7 18.8L32 46.2 15.1 55.5"
			+ "l3.7-18.8-14-13 19-2.3z"
		)
		color_superior = "#FFF59A"
		color_inferior = "#E58A05"
	else:
		forma = (
			"M32 57S6 40 6 22C6 12 13 6 21 6"
			+ "c5 0 9 3 11 7 2-4 6-7 11-7"
			+ " 8 0 15 6 15 16"
			+ " 0 18-26 35-26 35z"
		)
		color_superior = "#FF9EC0"
		color_inferior = "#C41A58"

	var relleno: String = "url(#g)" if lleno else "#2A1A5E"

	var codigo: String = """
<svg xmlns="http://www.w3.org/2000/svg"
	width="64" height="64" viewBox="0 0 64 64">
	<defs>
		<linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
			<stop offset="0" stop-color="%s"/>
			<stop offset="1" stop-color="%s"/>
		</linearGradient>
	</defs>
	<path d="%s" fill="%s"
		stroke="#1A0E3B" stroke-width="3.5"
		stroke-linejoin="round"/>
</svg>
""" % [
		color_superior,
		color_inferior,
		forma,
		relleno
	]

	return textura_svg(codigo)


func poner_simbolo(
	padre: Node,
	tipo: String,
	lleno: bool,
	posicion: Vector2,
	tamano: Vector2,
	retardo: float
) -> void:
	var imagen := TextureRect.new()
	imagen.texture = textura_simbolo(tipo, lleno)
	imagen.position = posicion
	imagen.size = tamano
	imagen.pivot_offset = tamano / 2.0
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(imagen)

	if not lleno:
		return

	if tipo == "estrella":
		imagen.scale = Vector2(0.1, 0.1)
		imagen.modulate.a = 0.0

		var entrada := imagen.create_tween()
		entrada.tween_interval(retardo)

		entrada.tween_property(
			imagen,
			"scale",
			Vector2.ONE,
			0.45
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		entrada.parallel().tween_property(
			imagen,
			"modulate:a",
			1.0,
			0.25
		)
	else:
		var latido := imagen.create_tween()
		latido.set_loops()
		latido.tween_interval(retardo)

		latido.tween_property(
			imagen,
			"scale",
			Vector2(1.1, 1.1),
			0.65
		).set_trans(Tween.TRANS_SINE)

		latido.tween_property(
			imagen,
			"scale",
			Vector2.ONE,
			0.65
		).set_trans(Tween.TRANS_SINE)


# ==================================================
# AUDIO
# ==================================================

func crear_audio() -> void:
	# Audio temporalmente desactivado para este nivel
	musica = AudioStreamPlayer.new()
	add_child(musica)

	efectos = AudioStreamPlayer.new()
	add_child(efectos)


func secuencia(
	notas: Array,
	duracion_nota: float,
	repetir: bool = false
) -> AudioStreamWAV:
	const FRECUENCIA: int = 22050

	var cantidad: int = int(
		notas.size() * duracion_nota * FRECUENCIA
	)
	var datos := PackedByteArray()
	datos.resize(cantidad * 2)

	for i in range(cantidad):
		var tiempo: float = float(i) / FRECUENCIA
		var indice: int = mini(
			int(tiempo / duracion_nota),
			notas.size() - 1
		)

		var frecuencia_nota: float = float(notas[indice])
		var local: float = fmod(tiempo, duracion_nota)
		var ataque: float = minf(local / 0.012, 1.0)
		var salida: float = minf(
			(duracion_nota - local) / 0.04,
			1.0
		)

		var onda: float = sin(TAU * frecuencia_nota * tiempo)
		onda += 0.15 * sin(
			TAU * frecuencia_nota * 2.0 * tiempo
		)
		onda *= maxf(ataque * salida, 0.0) * 0.2

		datos.encode_s16(
			i * 2,
			int(clampf(onda, -1.0, 1.0) * 32767.0)
		)

	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = FRECUENCIA
	audio.stereo = false
	audio.data = datos

	if repetir:
		audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
		audio.loop_begin = 0
		audio.loop_end = cantidad - 1

	return audio


func reproducir(audio: AudioStreamWAV) -> void:
	if efectos == null or audio == null:
		return
	efectos.stream = audio
	efectos.play()


func al_golpear() -> void:
	reproducir(golpe_audio)


func cambiar_musica(valor: float) -> void:
	volumen_musica = valor
	musica.volume_db = (
		-80.0 if valor <= 0.0
		else linear_to_db(valor / 100.0)
	)


func cambiar_efectos(valor: float) -> void:
	volumen_efectos = valor
	efectos.volume_db = (
		-80.0 if valor <= 0.0
		else linear_to_db(valor / 100.0)
	)


func agregar_volumen(y: float) -> void:
	var fondo_audio := Panel.new()
	fondo_audio.position = Vector2(30, y - 12)
	fondo_audio.size = Vector2(520, 126)

	fondo_audio.add_theme_stylebox_override(
		"panel",
		estilo(
			Color("#281650"),
			Color("#7656AD"),
			18,
			2
		)
	)
	tarjeta.add_child(fondo_audio)

	etiqueta(
		tarjeta,
		"♫  MÚSICA",
		Vector2(42, y),
		Vector2(145, 30),
		18,
		AMARILLO
	)
	etiqueta(
		tarjeta,
		"◖  SONIDOS",
		Vector2(42, y + 49),
		Vector2(145, 30),
		18,
		TURQUESA
	)

	var control_musica := HSlider.new()
	control_musica.position = Vector2(205, y)
	control_musica.size = Vector2(320, 32)
	control_musica.max_value = 100
	control_musica.value = volumen_musica
	decorar_slider(control_musica)
	control_musica.value_changed.connect(cambiar_musica)
	tarjeta.add_child(control_musica)

	var control_sonidos := HSlider.new()
	control_sonidos.position = Vector2(205, y + 49)
	control_sonidos.size = Vector2(320, 32)
	control_sonidos.max_value = 100
	control_sonidos.value = volumen_efectos
	decorar_slider(control_sonidos)
	control_sonidos.value_changed.connect(cambiar_efectos)
	tarjeta.add_child(control_sonidos)


func decorar_slider(control: HSlider) -> void:
	var pista := estilo(
		Color("#251650"),
		Color("#1A0E3B"),
		8,
		2
	)
	pista.content_margin_top = 5
	pista.content_margin_bottom = 5

	var relleno := estilo(
		Color("#6EE7F7"),
		Color("#1A0E3B"),
		8,
		2
	)
	relleno.content_margin_top = 5
	relleno.content_margin_bottom = 5

	control.add_theme_stylebox_override("slider", pista)
	control.add_theme_stylebox_override("grabber_area", relleno)
	control.add_theme_stylebox_override(
		"grabber_area_highlight",
		relleno
	)

	var perilla: Texture2D = textura_svg("""
<svg xmlns="http://www.w3.org/2000/svg"
	width="32" height="34">
	<defs>
		<radialGradient id="g" cx=".35" cy=".3" r=".75">
			<stop offset="0" stop-color="#FFFFFF"/>
			<stop offset=".45" stop-color="#FFE566"/>
			<stop offset="1" stop-color="#E8920D"/>
		</radialGradient>
	</defs>
	<circle cx="16" cy="19" r="13" fill="#130827"/>
	<circle cx="16" cy="15" r="12"
		fill="url(#g)" stroke="#1A0E3B" stroke-width="3"/>
</svg>
""")

	control.add_theme_icon_override("grabber", perilla)
	control.add_theme_icon_override("grabber_highlight", perilla)


# ==================================================
# CIENTÍFICO ANIMADO
# ==================================================

class CientificoAnimado:
	extends Control

	const BORDE := Color("#29203E")
	const PIEL := Color("#FFD4AE")
	const CABELLO := Color("#F2F0FF")
	const CHAQUETA := Color("#357BA5")

	var gano: bool = true
	var tiempo: float = 0.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		tiempo += delta
		queue_redraw()

	func _draw() -> void:
		var escala: float = minf(
			size.x / 250.0,
			size.y / 300.0
		)
		var desplazamiento := Vector2(
			(size.x - 250.0 * escala) / 2.0,
			0
		)

		draw_set_transform(
			desplazamiento + Vector2(125, 286) * escala,
			0.0,
			Vector2(escala, escala * 0.2)
		)
		draw_circle(
			Vector2.ZERO,
			65.0,
			Color(0.12, 0.05, 0.22, 0.3)
		)

		var balanceo: float = sin(tiempo * 3.0) * 3.0

		if gano:
			balanceo = -absf(sin(tiempo * 4.0)) * 7.0

		draw_set_transform(
			desplazamiento + Vector2(0, balanceo * escala),
			0.0,
			Vector2(escala, escala)
		)

		# Piernas y zapatos.
		draw_line(
			Vector2(105, 223), Vector2(101, 270),
			BORDE, 20.0, true
		)
		draw_line(
			Vector2(145, 223), Vector2(151, 270),
			BORDE, 20.0, true
		)
		draw_line(
			Vector2(85, 275), Vector2(108, 275),
			BORDE, 17.0, true
		)
		draw_line(
			Vector2(145, 275), Vector2(168, 275),
			BORDE, 17.0, true
		)

		var mano_izquierda := Vector2(49, 214)
		var mano_derecha := Vector2(
			176 + sin(tiempo * 2.0) * 3.0,
			118
		)

		if gano:
			mano_izquierda = Vector2(
				43,
				130 + sin(tiempo * 5.0) * 10.0
			)
			mano_derecha = Vector2(
				207,
				112 + sin(tiempo * 5.0 + 1.0) * 13.0
			)

		brazo(Vector2(87, 169), mano_izquierda)
		brazo(Vector2(163, 169), mano_derecha)

		# Abrigo.
		var abrigo := PackedVector2Array([
			Vector2(88, 151),
			Vector2(162, 151),
			Vector2(177, 242),
			Vector2(137, 251),
			Vector2(125, 231),
			Vector2(113, 251),
			Vector2(73, 242)
		])

		draw_colored_polygon(abrigo, CHAQUETA)

		var contorno := PackedVector2Array(abrigo)
		contorno.append(abrigo[0])
		draw_polyline(contorno, BORDE, 4.0, true)

		# Chaleco.
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(104, 156),
				Vector2(146, 156),
				Vector2(143, 224),
				Vector2(108, 224)
			]),
			Color("#B287D1")
		)

		for y in [185.0, 200.0, 215.0]:
			draw_circle(
				Vector2(126, y),
				3.0,
				Color("#FFE075")
			)

		# Pañuelo y cuello.
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(106, 149),
				Vector2(144, 149),
				Vector2(135, 174),
				Vector2(125, 183),
				Vector2(115, 174)
			]),
			CABELLO
		)

		draw_line(
			Vector2(125, 134),
			Vector2(125, 155),
			PIEL,
			22.0
		)

		# Peluca.
		for centro in [
			Vector2(87, 81),
			Vector2(99, 59),
			Vector2(122, 51),
			Vector2(148, 58),
			Vector2(166, 77),
			Vector2(83, 104),
			Vector2(81, 128),
			Vector2(90, 149),
			Vector2(170, 104),
			Vector2(171, 128),
			Vector2(161, 149)
		]:
			draw_circle(centro, 18.0, BORDE)
			draw_circle(centro, 14.5, CABELLO)

		# Cara.
		draw_circle(Vector2(125, 105), 40.0, BORDE)
		draw_circle(Vector2(125, 105), 36.5, PIEL)

		for centro in [
			Vector2(99, 77),
			Vector2(115, 68),
			Vector2(135, 68),
			Vector2(152, 78)
		]:
			draw_circle(centro, 12.0, CABELLO)

		draw_circle(Vector2(87, 110), 8.0, PIEL)
		draw_circle(Vector2(163, 110), 8.0, PIEL)

		# Cejas.
		draw_line(
			Vector2(105, 91), Vector2(117, 89),
			Color("#AAA7BE"), 4.0, true
		)
		draw_line(
			Vector2(135, 89), Vector2(147, 91),
			Color("#AAA7BE"), 4.0, true
		)

		# Ojos y parpadeo.
		var parpadeando: bool = fmod(tiempo, 4.0) > 3.8

		if parpadeando:
			draw_line(
				Vector2(106, 102), Vector2(116, 102),
				BORDE, 3.0
			)
			draw_line(
				Vector2(136, 102), Vector2(146, 102),
				BORDE, 3.0
			)
		else:
			for ojo in [Vector2(111, 102), Vector2(141, 102)]:
				draw_circle(ojo, 6.0, Color.WHITE)
				draw_circle(ojo + Vector2(1, 0), 3.5, BORDE)
				draw_circle(
					ojo + Vector2(2, -1),
					1.0,
					Color.WHITE
				)

		draw_circle(
			Vector2(127, 114),
			5.0,
			Color("#E8A47F")
		)
		draw_circle(
			Vector2(101, 119),
			5.0,
			Color("#F3A9A0")
		)
		draw_circle(
			Vector2(151, 119),
			5.0,
			Color("#F3A9A0")
		)

		if gano:
			draw_arc(
				Vector2(126, 119),
				13.0,
				0.15,
				PI - 0.15,
				20,
				BORDE,
				3.0,
				true
			)
		else:
			draw_line(
				Vector2(119, 131),
				Vector2(133, 129),
				BORDE,
				3.0,
				true
			)

		draw_set_transform(Vector2.ZERO)

	func brazo(inicio: Vector2, mano: Vector2) -> void:
		draw_line(inicio, mano, BORDE, 19.0, true)
		draw_line(inicio, mano, CHAQUETA, 13.0, true)
		draw_circle(mano, 11.0, BORDE)
		draw_circle(mano, 8.0, PIEL)
