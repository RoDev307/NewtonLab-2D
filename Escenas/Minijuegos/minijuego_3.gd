extends Node2D

var eliminados: int = 0
var terminado: bool = false

@onready var nave = $naveJugador
@onready var etiqueta: Label = $CanvasLayer/Label
@onready var sfx: AudioStreamPlayer = $SFX
@onready var musica_fondo: AudioStreamPlayer = $MusicaFondo

# Rutas de las texturas para los cursores
var cursor_mirilla: Texture2D = preload("res://Assets/Cursor/PNG/Outline/Default/target_a.png")

# Sonidos pregenerados o cargados
var sonido_disparo: AudioStream = null
var sonido_explosion: AudioStreamWAV = null
var sonido_derrota: AudioStreamWAV = null

func _ready() -> void:
	# Asegurar desmutear Master
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	
	_iniciar_musica()

	# Activar la mirilla con el hotspot centrado
	if cursor_mirilla:
		var centro_hotspot := cursor_mirilla.get_size() / 2.0
		Input.set_custom_mouse_cursor(cursor_mirilla, Input.CURSOR_ARROW, centro_hotspot)
	
	if is_instance_valid(sfx):
		sfx.max_polyphony = 6
		var idx_sfx = AudioServer.get_bus_index("SFX")
		sfx.bus = &"SFX" if idx_sfx != -1 else &"Master"
		if idx_sfx != -1:
			AudioServer.set_bus_mute(idx_sfx, false)
	
	_generar_sonidos()

func _unhandled_input(event: InputEvent) -> void:
	# El primer clic en el nivel desbloquea el audio si el navegador lo bloqueó
	if event is InputEventMouseButton and event.pressed:
		_desbloquear_audio_web()

func _desbloquear_audio_web() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	_iniciar_musica()

func _iniciar_musica() -> void:
	if is_instance_valid(musica_fondo) and not musica_fondo.playing:
		musica_fondo.play()

func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)

func _generar_sonidos() -> void:
	var ruta_laser := "res://Assets/Audio/Sci-Fi/Audio/laserRetro_001.ogg"
	if ResourceLoader.exists(ruta_laser):
		sonido_disparo = load(ruta_laser)
	else:
		sonido_disparo = _crear_tono_sintetizado([600, 400, 250], 0.05)
	
	sonido_explosion = _crear_ruido_sintetizado(0.2)
	sonido_derrota = _crear_tono_sintetizado([300, 220, 150, 90], 0.12)

func reproducir_sfx(tipo: String) -> void:
	if not is_instance_valid(sfx):
		return
		
	match tipo:
		"disparo":
			if sonido_disparo:
				sfx.stream = sonido_disparo
				sfx.play()
		"explosion":
			if sonido_explosion:
				sfx.stream = sonido_explosion
				sfx.play()
		"derrota":
			if sonido_derrota:
				sfx.stream = sonido_derrota
				sfx.play()

func sumar_eliminado() -> void:
	eliminados += 1
	etiqueta.text = "Enemigos eliminados: " + str(eliminados)
	reproducir_sfx("explosion")

func perder() -> void:
	if terminado:
		return
	terminado = true
	reproducir_sfx("derrota")
	etiqueta.text = "¡Te atraparon! Eliminados: " + str(eliminados)
	nave.hide()
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()

# --- Frecuencia corregida a 44100 Hz ---
func _crear_tono_sintetizado(notas: Array, duracion_nota: float) -> AudioStreamWAV:
	const FRECUENCIA: int = 44100
	var cantidad: int = int(notas.size() * duracion_nota * FRECUENCIA)
	var datos := PackedByteArray()
	datos.resize(cantidad * 2)

	for i in range(cantidad):
		var tiempo: float = float(i) / FRECUENCIA
		var indice: int = mini(int(tiempo / duracion_nota), notas.size() - 1)
		var freq: float = float(notas[indice])
		var local: float = fmod(tiempo, duracion_nota)
		var env: float = minf(local / 0.005, 1.0) * minf((duracion_nota - local) / 0.02, 1.0)
		var onda: float = sin(TAU * freq * tiempo) * env * 0.25
		datos.encode_s16(i * 2, int(clampf(onda, -1.0, 1.0) * 32767.0))

	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = FRECUENCIA
	audio.data = datos
	return audio

func _crear_ruido_sintetizado(duracion: float) -> AudioStreamWAV:
	const FRECUENCIA: int = 44100
	var cantidad: int = int(duracion * FRECUENCIA)
	var datos := PackedByteArray()
	datos.resize(cantidad * 2)

	for i in range(cantidad):
		var t: float = float(i) / cantidad
		var envolvente: float = (1.0 - t) * (1.0 - t)
		var ruido: float = randf_range(-1.0, 1.0) * envolvente * 0.3
		datos.encode_s16(i * 2, int(clampf(ruido, -1.0, 1.0) * 32767.0))

	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = FRECUENCIA
	audio.data = datos
	return audio
