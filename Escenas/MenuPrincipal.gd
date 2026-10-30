extends Control

# Rutas de las escenas a las que conducirá cada botón
const RUTA_LEY_1: String = "res://Escenas/Minijuegos/Minijuego1_Inercia.tscn"
const RUTA_LEY_2: String = "res://Escenas/Minijuegos/Minijuego2_Canon.tscn"
const RUTA_LEY_3: String = "res://Escenas/Minijuegos/Minijuego3_AccionReaccion.tscn"
const RUTA_BILLAR: String = "res://Escenas/Minijuegos/Minijuego_BillarCompleto.tscn"

@onready var boton_cerrar: Button = $BotonCerrar
@onready var boton_ley1: Button = $CentroContenedor/BotonesContainer/BotonLey1
@onready var boton_ley2: Button = $CentroContenedor/BotonesContainer/BotonLey2
@onready var boton_ley3: Button = $CentroContenedor/BotonesContainer/BotonLey3
@onready var boton_billar: Button = $CentroContenedor/BotonesContainer/BotonBillar

func _ready() -> void:
	# Conexión limpia de señales de los botones
	boton_cerrar.pressed.connect(_on_boton_cerrar_pressed)
	boton_ley1.pressed.connect(_on_boton_ley1_pressed)
	boton_ley2.pressed.connect(_on_boton_ley2_pressed)
	boton_ley3.pressed.connect(_on_boton_ley3_pressed)
	boton_billar.pressed.connect(_on_boton_billar_pressed)

func _on_boton_cerrar_pressed() -> void:
	# Cierra la aplicación de forma segura
	get_tree().quit()

func _on_boton_ley1_pressed() -> void:
	_cambiar_escena(RUTA_LEY_1)

func _on_boton_ley2_pressed() -> void:
	_cambiar_escena(RUTA_LEY_2)

func _on_boton_ley3_pressed() -> void:
	_cambiar_escena(RUTA_LEY_3)

func _on_boton_billar_pressed() -> void:
	_cambiar_escena(RUTA_BILLAR)

func _cambiar_escena(ruta_archivo: String) -> void:
	# Validar existencia del archivo para evitar caídas si una escena aún no se crea
	if ResourceLoader.exists(ruta_archivo):
		get_tree().change_scene_to_file(ruta_archivo)
	else:
		push_warning("La escena aún no ha sido creada: " + ruta_archivo)
