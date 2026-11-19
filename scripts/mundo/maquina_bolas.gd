class_name MaquinaBolas
extends Node2D
## Máquina de bolas de la sala de entrenamiento. Lanza bolas al lado del jugador según el modo.
## Solo lanza: cuándo lo hace lo decide quien la use (Entrenamiento).

signal lanzo(modo: ModoMaquina)
signal modo_cambiado(modo: ModoMaquina)

@export var modos: Array[ModoMaquina] = []
## Posición lógica de la que salen las bolas (detrás de la línea de fondo del rival).
@export var origen_logico: Vector2 = Vector2(90.0, -6.0)
@export var altura_salida: float = 18.0
## Margen mínimo sobre la red que se asegura al lanzar.
@export var margen_red: float = 4.0

@onready var _sprite: Sprite2D = $Sprite

var indice: int = 0
var pista: Pista
var bola: Bola

var _alterna: float = 1.0
var _flash: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func configurar(p: Pista, b: Bola, semilla: int) -> void:
	pista = p
	bola = b
	_rng.seed = semilla
	_sprite.global_position = pista.proyectar(origen_logico).round()


func modo() -> ModoMaquina:
	return modos[indice]


func siguiente_modo() -> void:
	indice = (indice + 1) % modos.size()
	modo_cambiado.emit(modo())


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	_sprite.modulate = Color(2.0, 2.0, 2.0) if _flash > 0.0 else Color.WHITE


func lanzar() -> void:
	var m: ModoMaquina = modo()
	var rect: Rect2 = pista.rect_juego()
	var y_red: float = pista.y_red()
	var centro: float = rect.position.x + rect.size.x * 0.5
	var dx: float = 0.0
	var dist: float = _rng.randf_range(40.0, 92.0)
	match m.destino:
		ModoMaquina.Destino.ALEATORIO:
			dx = _rng.randf_range(-70.0, 70.0)
		ModoMaquina.Destino.DERECHA:
			dx = _rng.randf_range(48.0, 70.0)
		ModoMaquina.Destino.IZQUIERDA:
			dx = _rng.randf_range(-70.0, -48.0)
		ModoMaquina.Destino.CENTRO:
			dx = _rng.randf_range(-14.0, 14.0)
		ModoMaquina.Destino.CORTA:
			dx = _rng.randf_range(-45.0, 45.0)
			dist = _rng.randf_range(20.0, 34.0)
		ModoMaquina.Destino.PROFUNDA:
			dx = _rng.randf_range(-45.0, 45.0)
			dist = _rng.randf_range(84.0, 96.0)
		ModoMaquina.Destino.ESQUINAS:
			_alterna = -_alterna
			dx = _alterna * _rng.randf_range(58.0, 70.0)
			dist = _rng.randf_range(84.0, 96.0)
	var destino: Vector2 = Vector2(centro + dx, y_red + dist)
	var tiempo: float = m.tipo.tiempo_vuelo * m.factor_tiempo
	if m.usa_ritmo and bola.ritmo != null:
		tiempo *= bola.ritmo.factor_tiempo(bola.golpes_en_juego)
	elif not m.usa_ritmo:
		bola.golpes_en_juego = 0
	tiempo = Golpe.tiempo_con_red(bola.params.gravedad, origen_logico, altura_salida, destino, tiempo,
			y_red, pista.alto_red, margen_red)
	var potencia: float = m.potencia if m.potencia >= 0.0 else m.tipo.potencia
	bola.ultimo_golpeador = Personaje.Lado.ARRIBA
	bola.lanzar_hacia(origen_logico, altura_salida, destino, tiempo, potencia)
	bola.golpes_en_juego += 1
	_flash = 0.08
	lanzo.emit(m)
