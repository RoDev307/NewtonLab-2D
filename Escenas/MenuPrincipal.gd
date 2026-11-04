extends Control

# Rutas de las escenas
const RUTA_LEY_1: String = "res://Escenas/Minijuegos/Minijuego1_Inercia.tscn"
const RUTA_LEY_2: String = "res://Escenas/Minijuegos/Minijuego2_Canon.tscn"
const RUTA_LEY_3: String = "res://Escenas/Minijuegos/Minijuego3_AccionReaccion.tscn"
const RUTA_BILLAR: String = "res://Escenas/Minijuegos/Minijuego_BillarCompleto.tscn"

# Nodos del Menú
@onready var boton_cerrar = $BotonCerrar
@onready var boton_ley1 = $CentroContenedor/BotonesContainer/BotonLey1
@onready var boton_ley2 = $CentroContenedor/BotonesContainer/BotonLey2
@onready var boton_ley3 = $CentroContenedor/BotonesContainer/BotonLey3
@onready var boton_billar = $CentroContenedor/BotonesContainer/BotonBillar

# Nodos de Configuración
@onready var boton_config = $BotonConfiguracion
@onready var panel_opciones: Control = $PanelOpciones
@onready var slider_musica: HSlider = $PanelOpciones/MarginContainer/VBoxContainer/ContenedorMusica/SliderMusica
@onready var slider_ui: HSlider = $PanelOpciones/MarginContainer/VBoxContainer/ContenedorUI/SliderUI
@onready var boton_cerrar_opciones = $PanelOpciones/MarginContainer/VBoxContainer/BotonCerrarOpciones

# Nodos de Créditos
@onready var boton_creditos = $BotonCreditos
@onready var panel_creditos: Control = $PanelCreditos
@onready var boton_cerrar_creditos = $PanelCreditos/MarginContainer/VBoxContainer/BotonCerrarCreditos

@onready var musica_fondo: AudioStreamPlayer = $MusicaFondo
@onready var audio_clic: AudioStreamPlayer = $AudioClic

# Índices de los Autobuses de Audio
var index_musica: int = -1
var index_ui: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Desmutear bus principal
	var idx_master = AudioServer.get_bus_index("Master")
	if idx_master != -1:
		AudioServer.set_bus_mute(idx_master, false)

	# Buscar buses por nombre ("Música", "Musica" o "Master")
	index_musica = AudioServer.get_bus_index("Música")
	if index_musica == -1:
		index_musica = AudioServer.get_bus_index("Musica")
	if index_musica == -1:
		index_musica = idx_master

	# Buscar bus de UI o SFX
	index_ui = AudioServer.get_bus_index("UI")
	if index_ui == -1:
		index_ui = AudioServer.get_bus_index("SFX")
	if index_ui == -1:
		index_ui = idx_master

	# Asegurar que los buses no estén silenciados
	if index_musica != -1:
		AudioServer.set_bus_mute(index_musica, false)
		AudioServer.set_bus_volume_db(index_musica, linear_to_db(0.8))
	if index_ui != -1:
		AudioServer.set_bus_mute(index_ui, false)
		AudioServer.set_bus_volume_db(index_ui, linear_to_db(0.8))

	_inicializar_sliders()

	# Carga segura de la música si la escena no tiene stream asignado
	if is_instance_valid(musica_fondo):
		musica_fondo.bus = &"Musica" if AudioServer.get_bus_index("Musica") != -1 else &"Master"
		if musica_fondo.stream == null:
			var ruta_menu_ogg := "res://Assets/Audio/Music/PrimordialSoupBASE.ogg" # Ajusta a la ruta de tu tema del menú
			if ResourceLoader.exists(ruta_menu_ogg):
				musica_fondo.stream = load(ruta_menu_ogg)

	# Conexiones de botones principales
	if is_instance_valid(boton_cerrar):
		boton_cerrar.pressed.connect(_on_boton_cerrar_pressed)
	if is_instance_valid(boton_ley1):
		boton_ley1.pressed.connect(func(): _cambiar_escena(RUTA_LEY_1))
	if is_instance_valid(boton_ley2):
		boton_ley2.pressed.connect(func(): _cambiar_escena(RUTA_LEY_2))
	if is_instance_valid(boton_ley3):
		boton_ley3.pressed.connect(func(): _cambiar_escena(RUTA_LEY_3))
	if is_instance_valid(boton_billar):
		boton_billar.pressed.connect(func(): _cambiar_escena(RUTA_BILLAR))

	# Conexión Panel de Opciones
	if is_instance_valid(boton_config) and is_instance_valid(panel_opciones):
		boton_config.pressed.connect(func(): _abrir_panel(panel_opciones))
	if is_instance_valid(boton_cerrar_opciones) and is_instance_valid(panel_opciones):
		boton_cerrar_opciones.pressed.connect(func(): _cerrar_panel(panel_opciones))

	if is_instance_valid(slider_musica):
		slider_musica.value_changed.connect(_on_slider_musica_value_changed)
	if is_instance_valid(slider_ui):
		slider_ui.value_changed.connect(_on_slider_ui_value_changed)

	# Conexión Panel de Créditos
	if is_instance_valid(boton_creditos) and is_instance_valid(panel_creditos):
		boton_creditos.pressed.connect(func(): _abrir_panel(panel_creditos))
	if is_instance_valid(boton_cerrar_creditos) and is_instance_valid(panel_creditos):
		boton_cerrar_creditos.pressed.connect(func(): _cerrar_panel(panel_creditos))

	_iniciar_audio()

# Usar _input en lugar de _unhandled_input para capturar los clics incluso sobre los botones
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_desbloquear_audio_web()

func _iniciar_audio() -> void:
	if is_instance_valid(musica_fondo) and musica_fondo.stream != null and not musica_fondo.playing:
		musica_fondo.play()

func _desbloquear_audio_web() -> void:
	var idx_master = AudioServer.get_bus_index("Master")
	if idx_master != -1:
		AudioServer.set_bus_mute(idx_master, false)
	_iniciar_audio()

func _inicializar_sliders() -> void:
	if index_musica != -1 and is_instance_valid(slider_musica):
		slider_musica.value = db_to_linear(AudioServer.get_bus_volume_db(index_musica))
	if index_ui != -1 and is_instance_valid(slider_ui):
		slider_ui.value = db_to_linear(AudioServer.get_bus_volume_db(index_ui))

func _abrir_panel(panel: Control) -> void:
	_reproducir_clic()
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	panel.show()
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)

func _cerrar_panel(panel: Control) -> void:
	_reproducir_clic()
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	await tween.finished
	panel.hide()

func _on_slider_musica_value_changed(value: float) -> void:
	if index_musica != -1:
		AudioServer.set_bus_volume_db(index_musica, linear_to_db(value))
		AudioServer.set_bus_mute(index_musica, value <= 0.01)

func _on_slider_ui_value_changed(value: float) -> void:
	if index_ui != -1:
		AudioServer.set_bus_volume_db(index_ui, linear_to_db(value))
		AudioServer.set_bus_mute(index_ui, value <= 0.01)

func _reproducir_clic() -> void:
	if is_instance_valid(audio_clic):
		audio_clic.play()

func _on_boton_cerrar_pressed() -> void:
	_reproducir_clic()
	if is_instance_valid(audio_clic):
		await audio_clic.finished
	get_tree().quit()

func _cambiar_escena(ruta_archivo: String) -> void:
	_reproducir_clic()
	if is_instance_valid(audio_clic):
		await audio_clic.finished
	
	if ResourceLoader.exists(ruta_archivo):
		get_tree().change_scene_to_file(ruta_archivo)
	else:
		push_warning("La escena aún no ha sido creada: " + ruta_archivo)
