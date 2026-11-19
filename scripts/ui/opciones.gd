extends Node
## Opciones del jugador (volúmenes y pantalla). Autoload `Opciones`; se guardan en user://opciones.cfg.

const RUTA: String = "user://opciones.cfg"
## Desplazamiento fijo de cada bus (el ambiente va más bajo que los efectos).
const DESPLAZAMIENTO_DB: Dictionary = {"Ambiente": -6.0}

var volumen_general: float = 0.8
var volumen_efectos: float = 1.0
var volumen_ambiente: float = 0.8
var pantalla_completa: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cargar()
	aplicar()


func cargar() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return
	volumen_general = cfg.get_value("audio", "general", volumen_general)
	volumen_efectos = cfg.get_value("audio", "efectos", volumen_efectos)
	volumen_ambiente = cfg.get_value("audio", "ambiente", volumen_ambiente)
	pantalla_completa = cfg.get_value("video", "pantalla_completa", pantalla_completa)


func guardar() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "general", volumen_general)
	cfg.set_value("audio", "efectos", volumen_efectos)
	cfg.set_value("audio", "ambiente", volumen_ambiente)
	cfg.set_value("video", "pantalla_completa", pantalla_completa)
	cfg.save(RUTA)


func aplicar() -> void:
	_bus(&"Master", volumen_general)
	_bus(&"Efectos", volumen_efectos)
	_bus(&"UI", volumen_efectos)
	_bus(&"Ambiente", volumen_ambiente)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_FULLSCREEN if pantalla_completa else DisplayServer.WINDOW_MODE_WINDOWED)


func _bus(nombre: StringName, lineal: float) -> void:
	var indice: int = AudioServer.get_bus_index(nombre)
	if indice < 0:
		return
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(lineal, 0.0001)) + DESPLAZAMIENTO_DB.get(String(nombre), 0.0))
	AudioServer.set_bus_mute(indice, lineal <= 0.001)
