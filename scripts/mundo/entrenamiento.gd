class_name Entrenamiento
extends Node2D
## Sala de entrenamiento: una máquina lanza bolas y tú las devuelves, sin rival ni marcador.
## Cuenta devoluciones y racha para probar el feel. LB/Q cambia de modo; Back/E lanza ya.

enum Estado { ESPERA, VUELO }

@export var semilla: int = 1
@export var espera_inicial: float = 1.2
## Tiempo máximo de una bola antes de darla por perdida.
@export var tiempo_maximo_bola: float = 9.0

@onready var pista: Pista = $Pista
@onready var bola: Bola = $Bola
@onready var jugador: Personaje = $Jugador
@onready var maquina: MaquinaBolas = $Maquina
@onready var efectos: EfectosGolpe = $Efectos
@onready var sonidos: SonidosPartido = $Sonidos
@onready var camara: CamaraFeel = $Camara
@onready var _entrada: EntradaHumana = $Jugador/EntradaHumana
@onready var _modo: Label = $UI/Modo
@onready var _racha: Label = $UI/Racha
@onready var _stats: Label = $UI/Stats
@onready var _barra_ritmo: ColorRect = $UI/RitmoBarra

var estado: Estado = Estado.ESPERA
var devoluciones: int = 0
var fuera: int = 0
var fallos: int = 0
var racha: int = 0
var mejor_racha: int = 0
var perfectos: int = 0
var parries: int = 0
var planchas: int = 0
## Qué pasó con la última bola: dentro, fuera, red o fallo.
var ultimo_resultado: String = ""

var _t_espera: float = 0.0
var _t_vuelo: float = 0.0


func _ready() -> void:
	bola.pista = pista
	jugador.configurar(pista, bola, semilla)
	jugador.golpes_habilitados = true
	_entrada.configurar(jugador)
	efectos.camara = camara
	efectos.conectar([jugador], bola, pista)
	sonidos.conectar([jugador], bola)
	maquina.configurar(pista, bola, semilla + 1)
	maquina.lanzo.connect(func(_m: ModoMaquina) -> void: sonidos.reproducir(&"golpe_fuerte", -3.0))
	maquina.modo_cambiado.connect(func(_m: ModoMaquina) -> void:
		bola.golpes_en_juego = 0
		_t_espera = minf(_t_espera, 0.6)
		_actualizar_hud())
	jugador.golpe_realizado.connect(_on_golpe)
	bola.rebote.connect(_on_rebote)
	bola.golpeo_red.connect(_on_red)
	_t_espera = espera_inicial
	_actualizar_hud()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"entrenar_modo"):
		maquina.siguiente_modo()
	elif evento.is_action_pressed(&"entrenar_lanzar") and estado == Estado.ESPERA:
		_t_espera = 0.0


func _physics_process(delta: float) -> void:
	_barra_ritmo.size.x = roundf(58.0 * bola.ritmo.progreso(bola.golpes_en_juego)) if bola.ritmo != null else 0.0
	match estado:
		Estado.ESPERA:
			_t_espera -= delta
			if _t_espera <= 0.0:
				maquina.lanzar()
				estado = Estado.VUELO
				_t_vuelo = 0.0
		Estado.VUELO:
			_t_vuelo += delta
			if _t_vuelo > tiempo_maximo_bola:
				_terminar_bola(false, "fallo")


func _on_golpe(info: Dictionary) -> void:
	if info["perfecto"]:
		perfectos += 1
	if info["parry"]:
		parries += 1
	if info["emergencia"]:
		planchas += 1
	_actualizar_hud()


func _on_rebote(punto: Vector2, numero: int) -> void:
	if estado != Estado.VUELO:
		return
	if bola.ultimo_golpeador == Personaje.Lado.ARRIBA:
		# La bola de la máquina: si botó dos veces en tu lado, no la devolviste.
		if numero >= 2:
			_terminar_bola(false, "fallo")
	elif numero == 1:
		var dentro: bool = punto.y < pista.y_red() and pista.contiene(punto)
		_terminar_bola(dentro, "dentro" if dentro else "fuera")


func _on_red() -> void:
	if estado == Estado.VUELO and bola.ultimo_golpeador == Personaje.Lado.ABAJO:
		_terminar_bola(false, "red")


func _terminar_bola(bien: bool, resultado: String) -> void:
	estado = Estado.ESPERA
	_t_espera = maquina.modo().pausa
	ultimo_resultado = resultado
	if bien:
		devoluciones += 1
		racha += 1
		mejor_racha = maxi(mejor_racha, racha)
	else:
		racha = 0
		bola.golpes_en_juego = 0
		if resultado == "fallo":
			fallos += 1
		else:
			fuera += 1
	_actualizar_hud()


func _actualizar_hud() -> void:
	_modo.text = "MÁQUINA: %s  (LB/Q: cambiar)" % maquina.modo().nombre
	_racha.text = "RACHA %d   MEJOR %d" % [racha, mejor_racha]
	_stats.text = "DENTRO %d  FUERA %d  FALLOS %d\nPERFECTOS %d  PARRIES %d  PLANCHAS %d" % [
			devoluciones, fuera, fallos, perfectos, parries, planchas]
