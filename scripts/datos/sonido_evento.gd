class_name SonidoEvento
extends Resource
## Un sonido del juego: qué suena cuando pasa un evento. Para poner tu audio, cambia el stream.

## Identificador del evento (golpe_suave, parry, derrape...).
@export var id: StringName = &""
## Variantes: suena una al azar.
@export var streams: Array[AudioStream] = []
@export var volumen_db: float = 0.0
## Variación aleatoria del tono (±fracción). 0,05 = ±5 %.
@export_range(0.0, 0.5, 0.01) var variacion_tono: float = 0.05
@export var bus: StringName = &"Efectos"


func elegir(rng: RandomNumberGenerator) -> AudioStream:
	if streams.is_empty():
		return null
	return streams[rng.randi() % streams.size()]
