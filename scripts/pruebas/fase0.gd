extends Node2D
## Banco de pruebas de la fase 0: una máquina de bolas en el lado del rival.
## Clic en la pista = lanza una bola que botará justo ahí.
## No es parte del juego final; sirve para sentir la bola, su arco y el marcador de caída.

## Resolución base (píxeles del juego). Pixel art: 480x270, escalado entero.
@export var resolucion_base: Vector2i = Vector2i(480, 270)
## Tipos de golpe disponibles (datos en data/golpes/).
@export var tipos: Array[TipoGolpe] = []
## Segundos entre bolas en modo automático.
@export var intervalo_auto: float = 2.2
## Cuánto puede salirse de las líneas el destino aleatorio (para ver bolas "fuera").
@export var margen_fuera: float = 12.0

@onready var _pista: Pista = $Pista
@onready var _bola: Bola = $Bola
@onready var _origen: Marker2D = $OrigenMaquina
@onready var _huellas: Node2D = $Huellas
@onready var _info: Label = $UI/Info

var _indice: int = 0
var _auto_activo: bool = false
var _prediccion: Vector2 = Vector2.ZERO
var _error_prediccion: float = -1.0
var _t_auto: float = 0.0
var _ultimo_evento: String = "-"
var _toco_red: bool = false


func _ready() -> void:
	get_window().content_scale_size = resolucion_base
	_bola.pista = _pista
	_bola.rebote.connect(_on_rebote)
	_bola.golpeo_red.connect(func() -> void:
		_toco_red = true
		_ultimo_evento = "choca con la red")
	_bola.cruzo_red.connect(func(_abajo: bool) -> void: _ultimo_evento = "pasa la red")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pruebas_lanzar"):
		lanzar_a(_pista.desproyectar(get_global_mouse_position()))
	elif event.is_action_pressed(&"pruebas_tipo_normal"):
		_elegir(0)
	elif event.is_action_pressed(&"pruebas_tipo_fuerte"):
		_elegir(1)
	elif event.is_action_pressed(&"pruebas_tipo_globo"):
		_elegir(2)
	elif event.is_action_pressed(&"pruebas_auto"):
		_auto_activo = not _auto_activo


func _process(delta: float) -> void:
	if _auto_activo:
		_t_auto -= delta
		if _t_auto <= 0.0:
			_t_auto = intervalo_auto
			lanzar_a(_destino_aleatorio())
	_actualizar_info()


## Lanza una bola desde la máquina hacia `destino` (se limita a la mitad del jugador).
func lanzar_a(destino: Vector2) -> void:
	if tipos.is_empty():
		return
	var tipo: TipoGolpe = tipos[_indice]
	var r: Rect2 = _pista.rect_juego().grow(margen_fuera)
	var objetivo: Vector2 = Vector2(
		clampf(destino.x, r.position.x, r.end.x),
		clampf(destino.y, _pista.y_red() + 10.0, r.end.y))
	_bola.lanzar_hacia(_pista.desproyectar(_origen.global_position), tipo.altura_inicial, objetivo, tipo.tiempo_vuelo, tipo.potencia)
	_prediccion = _bola.punto_aterrizaje()
	_error_prediccion = -1.0
	_toco_red = false
	_ultimo_evento = "en el aire"


func _destino_aleatorio() -> Vector2:
	var r: Rect2 = _pista.rect_juego().grow(margen_fuera)
	return Vector2(
		randf_range(r.position.x, r.end.x),
		randf_range(_pista.y_red() + 10.0, r.end.y))


func _elegir(indice: int) -> void:
	if indice < tipos.size():
		_indice = indice


func _on_rebote(punto: Vector2, numero: int) -> void:
	if numero == 1 and not _toco_red:
		_error_prediccion = punto.distance_to(_prediccion)
		_ultimo_evento = "bote dentro" if _pista.contiene(punto) else "bote FUERA"
	_poner_huella(punto, _pista.contiene(punto))


# Efecto temporal por código (huella del bote): no es algo que se diseñe a mano.
func _poner_huella(punto: Vector2, dentro: bool) -> void:
	var huella: Polygon2D = Polygon2D.new()
	huella.polygon = PackedVector2Array([
		Vector2(2, 0), Vector2(0, 1.2), Vector2(-2, 0), Vector2(0, -1.2)])
	huella.color = Color(1, 1, 1, 0.8) if dentro else Color(0.55, 0.57, 0.65, 0.8)
	huella.position = _pista.proyectar(punto).round()
	_huellas.add_child(huella)
	var tween: Tween = create_tween()
	tween.tween_property(huella, "modulate:a", 0.0, 1.5)
	tween.tween_callback(huella.queue_free)


func _actualizar_info() -> void:
	var nombre: String = tipos[_indice].nombre if not tipos.is_empty() else "-"
	var error: String = "-" if _error_prediccion < 0.0 else "%.2f px" % _error_prediccion
	_info.text = "Golpe: %s  |  %s\nBotes: %d  |  Error marcador: %s\nClic: lanzar\n1/2/3: golpe   T: auto (%s)" % [
		nombre, _ultimo_evento, _bola.rebotes, error, "SI" if _auto_activo else "no"]
