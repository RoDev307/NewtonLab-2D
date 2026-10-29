extends Node2D

@onready var proyectil: RigidBody2D = $Escenario/Proyectil
const ANGULO_INICIAL: float = 26.565051177
var angulo_slider: HSlider
var valor_angulo: Label
var sonido: Node
var premiado: bool = false
var premio: Label
var boton_sonido: Button
var ultimo_impacto: int = -1000
var panel_datos: PanelContainer
var cuerpo_panel: VBoxContainer
var ver_vuelo: Button
var siguiente: Button
var explicacion: Label
var valor_fuerza: Label
var valor_masa: Label
var fondo_comparacion: ColorRect
var fuerza_slider: HSlider
var masa_slider: HSlider
var presets: Array[Button] = []
var anterior: Label
var actual: Label
var datos: Label
var estado: Label
var disparar: Button
var ambiente: Node2D
var progreso: ProgressBar
var cajas: Array[RigidBody2D] = []
var origenes: Array[Vector2] = []
var derribadas: Array[bool] = []

func _ready() -> void:
	# Diseño local de esta escena: no modifica la configuración del proyecto.
	var camara := Camera2D.new()
	camara.name = "CamaraCanon"
	camara.position = Vector2(640, 360)
	add_child(camara)
	get_viewport().size_changed.connect(_ajustar_vista)
	_ajustar_vista()
	$Escenario/Suelo.physics_material_override = PhysicsMaterial.new()
	$Escenario/Suelo.physics_material_override.friction = 0.8
	$Escenario/Suelo/SueloVisual.hide()
	ambiente = Node2D.new()
	ambiente.set_script(load("res://Escenas/Minijuegos/AmbienteCanon.gd"))
	ambiente.z_index = -10
	add_child(ambiente)
	sonido = Node.new()
	sonido.set_script(load("res://Escenas/Minijuegos/SonidoCanon.gd"))
	add_child(sonido)
	proyectil.contact_monitor = true
	proyectil.max_contacts_reported = 8
	proyectil.body_entered.connect(_impacto)
	_crear_cajas()
	_decorar_equipo()
	_crear_controles()
	proyectil.medicion_lista.connect(_registrar_medicion)
	_restaurar_comparacion()
	_actualizar()

func _ajustar_vista() -> void:
	var tam: Vector2 = get_viewport_rect().size
	var factor: float = minf(tam.x / 1280.0, tam.y / 720.0)
	$CamaraCanon.zoom = Vector2.ONE * factor

func _crear_cajas() -> void:
	for fila in range(3):
		for columna in range(2):
			var caja := RigidBody2D.new()
			caja.name = "Objetivo%d" % cajas.size()
			caja.position = Vector2(540 + columna * 48, 557 - fila * 47)
			caja.mass = 0.8
			var material := PhysicsMaterial.new()
			material.friction = 0.7
			material.bounce = 0.05
			caja.physics_material_override = material
			var colision := CollisionShape2D.new()
			var forma := RectangleShape2D.new()
			forma.size = Vector2(44, 44)
			colision.shape = forma
			caja.add_child(colision)
			_detalle(caja, "caja")
			$Escenario.add_child(caja)
			cajas.append(caja)
			origenes.append(caja.position)
			derribadas.append(false)

func _detalle(padre: Node2D, tipo: String) -> void:
	var dibujo := Node2D.new()
	dibujo.set_script(load("res://Escenas/Minijuegos/DetalleCanon.gd"))
	dibujo.tipo = tipo
	dibujo.name = "Detalle"
	padre.add_child(dibujo)

func _decorar_equipo() -> void:
	for visual in $Escenario/Canon.get_children():
		if visual is CanvasItem:
			visual.hide()
	_detalle($Escenario/Canon, "canon")
	$Escenario/Proyectil/CajaVisual.hide()
	_detalle(proyectil, "bola")

func _estilo(color: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.set_corner_radius_all(16)
	estilo.content_margin_left = 20
	estilo.content_margin_right = 20
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	return estilo

func _boton(texto: String, color: Color) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.focus_mode = Control.FOCUS_NONE
	boton.custom_minimum_size = Vector2(225, 40)
	boton.add_theme_font_size_override("font_size", 20)
	boton.add_theme_color_override("font_color", Color("102f3c"))
	boton.add_theme_stylebox_override("normal", _estilo(color))
	boton.add_theme_stylebox_override("hover", _estilo(color.lightened(0.15)))
	boton.add_theme_stylebox_override("pressed", _estilo(color.darkened(0.15)))
	boton.add_theme_stylebox_override("disabled", _estilo(Color("719098")))
	return boton

func _etiqueta(texto: String, tamano: int = 18) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	return etiqueta

func _crear_controles() -> void:
	# Franja superior: la información esencial sin cubrir el área de tiro.
	var cabecera := PanelContainer.new()
	cabecera.position = Vector2(140, 12)
	cabecera.custom_minimum_size = Vector2(1120, 42)
	cabecera.add_theme_stylebox_override("panel", _estilo(Color("153b4cf2")))
	add_child(cabecera)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 22)
	cabecera.add_child(fila)
	var titulo := _etiqueta("NEWTON LAB · Ley 2", 23)
	titulo.add_theme_color_override("font_color", Color("ffdf8b"))
	fila.add_child(titulo)
	datos = _etiqueta("", 20)
	datos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(datos)
	boton_sonido = Button.new()
	boton_sonido.focus_mode = Control.FOCUS_NONE
	boton_sonido.custom_minimum_size.x = 135
	boton_sonido.pressed.connect(_alternar_sonido)
	fila.add_child(boton_sonido)
	estado = _etiqueta("", 18)
	estado.position = Vector2(145, 65)
	estado.add_theme_color_override("font_color", Color("153b4c"))
	add_child(estado)
	premio = _etiqueta("★ MEDALLA · ¡Seis objetivos completados!", 20)
	premio.position = Vector2(720, 100)
	premio.add_theme_color_override("font_color", Color("153b4c"))
	premio.hide()
	add_child(premio)
	# Controles anclados a la tierra, fuera de la zona de vuelo.
	var base := PanelContainer.new()
	base.name = "BarraControles"
	base.position = Vector2(14, 602)
	base.custom_minimum_size = Vector2(1252, 108)
	base.add_theme_stylebox_override("panel", _estilo(Color("153b4cfb")))
	add_child(base)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 5)
	base.add_child(columna)
	var ajustes := HBoxContainer.new()
	ajustes.add_theme_constant_override("separation", 24)
	columna.add_child(ajustes)
	var grupo_fuerza := VBoxContainer.new()
	ajustes.add_child(grupo_fuerza)
	valor_fuerza = _etiqueta("", 18)
	grupo_fuerza.add_child(valor_fuerza)
	fuerza_slider = _control(grupo_fuerza, 1000, 20000, 500, 7000)
	var grupo_masa := VBoxContainer.new()
	ajustes.add_child(grupo_masa)
	valor_masa = _etiqueta("", 18)
	grupo_masa.add_child(valor_masa)
	masa_slider = _control(grupo_masa, 0.5, 25, 0.5, 1)
	var grupo_angulo := VBoxContainer.new()
	ajustes.add_child(grupo_angulo)
	valor_angulo = _etiqueta("", 18)
	grupo_angulo.add_child(valor_angulo)
	angulo_slider = _control(grupo_angulo, 10, 65, 0.001, ANGULO_INICIAL)
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 10)
	columna.add_child(botones)
	disparar = _boton("1. DISPARAR · Espacio", Color("ffca68"))
	disparar.pressed.connect(_disparar)
	botones.add_child(disparar)
	siguiente = _boton("2. PREPARAR OTRO", Color("85dfd0"))
	siguiente.pressed.connect(func(): get_tree().reload_current_scene())
	botones.add_child(siguiente)
	ver_vuelo = _boton("3. COMPARAR", Color("c2dafa"))
	ver_vuelo.pressed.connect(_alternar_panel)
	botones.add_child(ver_vuelo)
	for masa_ejemplo in [1, 5, 25]:
		var preset := Button.new()
		preset.text = "%d kg" % masa_ejemplo
		preset.custom_minimum_size = Vector2(73, 40)
		preset.focus_mode = Control.FOCUS_NONE
		preset.pressed.connect(func():
			if not proyectil.lanzado:
				masa_slider.value = masa_ejemplo)
		botones.add_child(preset)
		presets.append(preset)
	# Los resultados solo aparecen cuando se pulsa Comparar.
	fondo_comparacion = ColorRect.new()
	fondo_comparacion.color = Color(0.04, 0.12, 0.17, 0.72)
	fondo_comparacion.position = Vector2.ZERO
	fondo_comparacion.size = Vector2(1280, 720)
	fondo_comparacion.mouse_filter = Control.MOUSE_FILTER_STOP
	fondo_comparacion.z_index = 50
	add_child(fondo_comparacion)
	panel_datos = PanelContainer.new()
	panel_datos.position = Vector2(130, 132)
	panel_datos.custom_minimum_size = Vector2(1020, 0)
	panel_datos.add_theme_stylebox_override("panel", _estilo(Color("153b4c")))
	fondo_comparacion.add_child(panel_datos)
	cuerpo_panel = VBoxContainer.new()
	cuerpo_panel.add_theme_constant_override("separation", 18)
	panel_datos.add_child(cuerpo_panel)
	cuerpo_panel.add_child(_etiqueta("COMPARA TUS DOS ÚLTIMOS DISPAROS", 26))
	var tarjetas := HBoxContainer.new()
	tarjetas.add_theme_constant_override("separation", 20)
	cuerpo_panel.add_child(tarjetas)
	anterior = _tarjeta_comparacion(tarjetas)
	actual = _tarjeta_comparacion(tarjetas)
	explicacion = _etiqueta("", 20)
	explicacion.custom_minimum_size.x = 980
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cuerpo_panel.add_child(explicacion)
	var nota := _etiqueta("Empuje: 0.10 s · a medida = Δv/Δt menos gravedad, en la dirección del empuje.\nDistancia y aceleración en unidades de simulación. Las cajas no miden aceleración.", 16)
	cuerpo_panel.add_child(nota)
	var volver := _boton("VOLVER AL JUEGO", Color("85dfd0"))
	volver.pressed.connect(_alternar_panel)
	cuerpo_panel.add_child(volver)
	fondo_comparacion.hide()
	# Se conserva la variable de progreso sin añadir otra barra sobre el paisaje.
	progreso = ProgressBar.new()
	progreso.max_value = 6
	progreso.hide()
	add_child(progreso)

func _control(contenedor: VBoxContainer, minimo: float, maximo: float, paso: float, valor: float) -> HSlider:
	var control := HSlider.new()
	control.min_value = minimo
	control.max_value = maximo
	control.step = paso
	control.value = valor
	control.custom_minimum_size = Vector2(378, 22)
	control.focus_mode = Control.FOCUS_NONE
	control.value_changed.connect(func(_valor): _actualizar())
	contenedor.add_child(control)
	return control

func _actualizar() -> void:
	if datos == null:
		return
	var angulo := angulo_slider.value
	proyectil.angulo = angulo
	proyectil.direccion = Vector2.RIGHT.rotated(-deg_to_rad(angulo))
	valor_angulo.text = "  ÁNGULO: %.1f°" % angulo
	var detalle = $Escenario/Canon.get_node("Detalle")
	detalle.angulo = angulo
	detalle.queue_redraw()
	if not proyectil.lanzado:
		var giro := -(deg_to_rad(angulo) - atan(0.5))
		proyectil.position = $Escenario/Canon.position + Vector2(70, -70).rotated(giro)
	proyectil.fuerza = fuerza_slider.value
	proyectil.mass = masa_slider.value
	valor_fuerza.text = "FUERZA  %.0f N" % proyectil.fuerza
	valor_masa.text = "MASA  %.1f kg" % proyectil.mass
	datos.text = "F = m × a   |   a prevista: %.1f u/s²" % (proyectil.fuerza / proyectil.mass)
	get_tree().root.set_meta("canon_angulo", angulo)
	get_tree().root.set_meta("canon_ajustes", Vector2(proyectil.fuerza, proyectil.mass))
	queue_redraw()

func _tarjeta_comparacion(fila: HBoxContainer) -> Label:
	var etiqueta := _etiqueta("", 20)
	etiqueta.custom_minimum_size = Vector2(480, 170)
	etiqueta.add_theme_stylebox_override("normal", _estilo(Color("244f60")))
	fila.add_child(etiqueta)
	return etiqueta

func _texto_medicion(titulo: String, medicion: Dictionary) -> String:
	return "%s #%d\nFuerza: %.0f N · Masa: %.1f kg\nÁngulo: %.1f°\nAceleración prevista: %.1f u/s²\nAceleración medida: %.1f u/s²" % [titulo, medicion.get("numero", 1), medicion.fuerza, medicion.masa, medicion.get("angulo", ANGULO_INICIAL), medicion.teorica, medicion.medida]

func _refrescar_comparacion() -> void:
	var historial: Array = get_tree().root.get_meta("canon_historial", [])
	anterior.text = "DISPARO 1\nTodavía no hay resultados."
	actual.text = "DISPARO 2\nTodavía no hay resultados."
	explicacion.text = "1. Dispara. 2. Pulsa PREPARAR OTRO y cambia solo la masa. 3. Dispara otra vez y pulsa COMPARAR."
	ver_vuelo.text = "3. COMPARAR (%d/2)" % mini(historial.size(), 2)
	if historial.size() == 1:
		anterior.text = _texto_medicion("DISPARO", historial[0])
		explicacion.text = "Ya guardaste un disparo. Vuelve al juego, pulsa PREPARAR OTRO y cambia solo la masa; conserva fuerza y ángulo. Dispara y abre COMPARAR."
	elif historial.size() >= 2:
		var primero: Dictionary = historial[-2]
		var segundo: Dictionary = historial[-1]
		anterior.text = _texto_medicion("DISPARO", primero)
		actual.text = _texto_medicion("DISPARO", segundo)
		var misma_fuerza := is_equal_approx(float(primero.fuerza), float(segundo.fuerza))
		var misma_masa := is_equal_approx(float(primero.masa), float(segundo.masa))
		var mismo_angulo := absf(float(primero.get("angulo", ANGULO_INICIAL)) - float(segundo.get("angulo", ANGULO_INICIAL))) < 0.01
		if not mismo_angulo:
			explicacion.text = "Cambiaste el ángulo. F/m sigue siendo válido, pero para comparar el vuelo repite con el mismo ángulo y cambia solo masa o fuerza."
		elif misma_fuerza and not misma_masa:
			explicacion.text = "Misma fuerza y ángulo: la masa pasó de %.1f a %.1f kg. La aceleración medida pasó de %.1f a %.1f u/s². Al aumentar la masa, disminuye la aceleración: a = F/m." % [primero.masa, segundo.masa, primero.medida, segundo.medida]
		elif misma_masa and not misma_fuerza:
			explicacion.text = "Misma masa y ángulo: la fuerza pasó de %.0f a %.0f N y la aceleración de %.1f a %.1f u/s². Más fuerza produce más aceleración: a = F/m." % [primero.fuerza, segundo.fuerza, primero.medida, segundo.medida]
		elif misma_fuerza and misma_masa:
			explicacion.text = "Repetiste los mismos ajustes. Para demostrar la ley, prepara otro disparo y cambia solo la masa, conservando fuerza y ángulo."
		else:
			explicacion.text = "Cambiaste fuerza y masa a la vez. Para aislar su efecto, conserva el ángulo y cambia solo una de esas variables."

func _restaurar_comparacion() -> void:
	_refrescar_comparacion()
	var ajustes: Vector2 = get_tree().root.get_meta("canon_ajustes", Vector2(7000, 1))
	var angulo_guardado: float = get_tree().root.get_meta("canon_angulo", ANGULO_INICIAL)
	sonido.activo = get_tree().root.get_meta("canon_sonido", true)
	boton_sonido.text = "SONIDO: SÍ" if sonido.activo else "SONIDO: NO"
	fuerza_slider.value = ajustes.x
	masa_slider.value = ajustes.y
	angulo_slider.value = angulo_guardado

func _registrar_medicion(medicion: Dictionary) -> void:
	var historial: Array = get_tree().root.get_meta("canon_historial", [])
	var numero: int = get_tree().root.get_meta("canon_numero", 0) + 1
	get_tree().root.set_meta("canon_numero", numero)
	medicion["numero"] = numero
	historial.append(medicion)
	if historial.size() > 2:
		historial.pop_front()
	get_tree().root.set_meta("canon_historial", historial)
	siguiente.disabled = false
	_refrescar_comparacion()

func _unhandled_input(event: InputEvent) -> void:
	if fondo_comparacion.visible:
		if event.is_action_pressed("ui_cancel"):
			_alternar_panel()
		return
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		_disparar()
		get_viewport().set_input_as_handled()

func _disparar() -> void:
	if proyectil.lanzado or fondo_comparacion.visible:
		return
	siguiente.disabled = true
	ambiente.destello(proyectil.position)
	sonido.reproducir("disparo")
	proyectil.lanzar()
	fuerza_slider.editable = false
	masa_slider.editable = false
	angulo_slider.editable = false
	disparar.disabled = true
	for preset in presets:
		preset.disabled = true
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if estado == null:
		return
	var total := 0
	for i in range(cajas.size()):
		if proyectil.lanzado and (cajas[i].position.distance_to(origenes[i]) > 35 or absf(cajas[i].rotation) > 0.45):
			if not derribadas[i]:
				ambiente.destello(cajas[i].position)
			derribadas[i] = true
		if derribadas[i]:
			total += 1
	progreso.value = total
	if total == 6 and not premiado:
		premiado = true
		premio.show()
		sonido.reproducir("premio")
		for punto in [Vector2(460,430), Vector2(600,400), Vector2(740,430)]:
			ambiente.destello(punto)
	var historial: Array = get_tree().root.get_meta("canon_historial", [])
	var guia: String
	if proyectil.lanzado:
		guia = "Pulsa PREPARAR OTRO para ajustar el siguiente disparo; luego COMPARAR."
	elif historial.is_empty():
		guia = "Paso 1: ajusta y dispara. Para comparar, conserva fuerza y ángulo y cambia solo masa."
	else:
		guia = "Paso 2: cambia solo la masa y dispara. Paso 3: pulsa COMPARAR."
	estado.text = "Cajas %d/6 · %s" % [total, guia]

func _draw() -> void:
	if fuerza_slider == null or proyectil.lanzado:
		return
	var inicio: Vector2 = proyectil.position
	var aceleracion: Vector2 = proyectil.direccion * fuerza_slider.value / masa_slider.value
	for i in range(1, 28):
		var tiempo := i * 0.045
		var empuje := minf(tiempo, proyectil.DURACION)
		var punto: Vector2 = inicio + aceleracion * (0.5 * empuje * empuje + empuje * maxf(tiempo - empuje, 0)) + Vector2(0, 981) * tiempo * tiempo * 0.5
		if punto.y > 565 or punto.x > 1250:
			break
		draw_circle(punto, 3.0, Color(1, 1, 0.85, 0.65))
	var direccion: Vector2 = proyectil.direccion
	var fin := inicio + direccion * clampf(fuerza_slider.value / masa_slider.value * 0.016, 35, 240)
	draw_line(inicio, fin, Color("f2c94c"), 5)
	draw_line(fin, fin - direccion.rotated(0.5) * 18, Color("f2c94c"), 5)
	draw_line(fin, fin - direccion.rotated(-0.5) * 18, Color("f2c94c"), 5)

func _alternar_sonido() -> void:
	sonido.activo = not sonido.activo
	get_tree().root.set_meta("canon_sonido", sonido.activo)
	boton_sonido.text = "SONIDO: SÍ" if sonido.activo else "SONIDO: NO"
	if not sonido.activo:
		sonido.detener()

func _impacto(_cuerpo: Node) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - ultimo_impacto > 180:
		ultimo_impacto = ahora
		sonido.reproducir("impacto")

func _alternar_panel() -> void:
	_refrescar_comparacion()
	fondo_comparacion.visible = not fondo_comparacion.visible
