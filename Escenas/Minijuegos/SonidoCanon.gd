extends Node
# Sonidos sintetizados locales: sin descargas ni cambios al audio global.
var activo: bool = true
var reproductores: Dictionary = {}

func _ready() -> void:
	for tipo in ["disparo", "impacto", "premio"]:
		var reproductor := AudioStreamPlayer.new()
		reproductor.stream = _crear_sonido(tipo)
		reproductor.volume_db = -15 if tipo != "premio" else -18
		add_child(reproductor)
		reproductores[tipo] = reproductor

func reproducir(tipo: String) -> void:
	if activo:
		reproductores[tipo].play()

func detener() -> void:
	for reproductor in reproductores.values():
		reproductor.stop()

func _crear_sonido(tipo: String) -> AudioStreamWAV:
	var frecuencia := 22050
	var duracion := 0.72 if tipo == "premio" else 0.18
	var cantidad := int(frecuencia * duracion)
	var datos := PackedByteArray()
	datos.resize(cantidad * 2)
	for i in range(cantidad):
		var t := float(i) / frecuencia
		var envolvente := minf(t / 0.008, 1.0) * pow(1.0 - t / duracion, 2)
		var muestra: float
		if tipo == "premio":
			var notas := [523.25, 659.25, 783.99, 1046.5]
			var nota: float = notas[mini(int(t / 0.18), 3)]
			muestra = sin(TAU * nota * t) * 0.7 + sin(TAU * nota * 2 * t) * 0.15
		elif tipo == "disparo":
			muestra = sin(TAU * (170 * t - 280 * t * t)) * 0.75 + sin(i * 1.73) * 0.18
		else:
			muestra = sin(TAU * 240 * t) * 0.4 + sin(i * 2.17) * 0.4
		datos.encode_s16(i * 2, int(clampf(muestra * envolvente, -1, 1) * 28000))
	var sonido := AudioStreamWAV.new()
	sonido.format = AudioStreamWAV.FORMAT_16_BITS
	sonido.mix_rate = frecuencia
	sonido.data = datos
	return sonido
