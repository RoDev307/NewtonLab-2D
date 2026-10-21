extends Node2D

@onready var disco: DiscoInercia = $Disco
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var slider_friccion: HSlider = $UI/PanelControl/MarginContainer/VBoxContainer/HBoxFriccion/SliderFriccion
@onready var label_friccion: Label = $UI/PanelControl/MarginContainer/VBoxContainer/HBoxFriccion/LabelFriccion
@onready var label_info: Label = $UI/PanelControl/MarginContainer/VBoxContainer/LabelInfo
@onready var boton_empujar: Button = $UI/PanelControl/MarginContainer/VBoxContainer/HBoxBotones/BotonEmpujar
@onready var boton_reset: Button = $UI/PanelControl/MarginContainer/VBoxContainer/HBoxBotones/BotonReset

const IMPULSO_FUERZA: float = 350.0

func _ready() -> void:
	boton_empujar.pressed.connect(_on_boton_empujar_pressed)
	boton_reset.pressed.connect(_on_boton_reset_pressed)
	slider_friccion.value_changed.connect(_on_slider_friccion_changed)
	
	_actualizar_etiquetas()
	_reiniciar_posicion()

func _physics_process(_delta: float) -> void:
	if is_instance_valid(disco):
		var vel_ms: float = disco.linear_velocity.length() / disco.PPM
		label_info.text = "Velocidad: %.2f m/s\nFricción lineal: %.1f\nEstado: %s" % [
			vel_ms,
			disco.linear_damp,
			"En Movimiento" if vel_ms > 0.05 else "En Reposo"
		]

func _on_boton_empujar_pressed() -> void:
	# Solo empuja cuando se presiona el botón, hacia la derecha
	var direccion: Vector2 = Vector2.RIGHT
	disco.aplicar_impulso_inicial(direccion * IMPULSO_FUERZA)

func _on_boton_reset_pressed() -> void:
	_reiniciar_posicion()

func _on_slider_friccion_changed(valor: float) -> void:
	disco.configurar_friccion(valor)
	_actualizar_etiquetas()

func _actualizar_etiquetas() -> void:
	label_friccion.text = "Fricción: %.1f" % slider_friccion.value

func _reiniciar_posicion() -> void:
	var pos: Vector2 = spawn_point.global_position if is_instance_valid(spawn_point) else Vector2(200, 300)
	disco.reiniciar_en(pos)
	disco.configurar_friccion(slider_friccion.value)
