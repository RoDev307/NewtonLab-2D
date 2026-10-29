extends CanvasLayer

# Ruta directa hacia el menú principal
const RUTA_MENU_PRINCIPAL: String = "res://Escenas/MenuPrincipal.tscn"

@onready var boton_regresar: Button = $BotonRegresar

func _ready() -> void:
	boton_regresar.pressed.connect(_on_boton_regresar_pressed)

func _on_boton_regresar_pressed() -> void:
	get_tree().paused = false
	if ResourceLoader.exists(RUTA_MENU_PRINCIPAL):
		get_tree().change_scene_to_file(RUTA_MENU_PRINCIPAL)
	else:
		push_error("No se encontró la escena del Menú Principal en: " + RUTA_MENU_PRINCIPAL)
