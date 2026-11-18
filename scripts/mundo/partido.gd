class_name Partido
extends Node2D
## Árbitro y director del partido: saque, reglas de punto, marcador y reparto de eventos.
## Reglas de punto: bote fuera, bote en tu propio campo, red, o doble bote del rival.

signal punto_ganado(lado: int, motivo: String)
signal partido_terminado(ganador: int)

@export var puntos_para_ganar: int = 11
## El saque cambia cada tantos puntos (GDD §8).
@export var saque_cada: int = 2
@export var primer_servidor: Personaje.Lado = Personaje.Lado.ABAJO
## true = el jugador de abajo lo lleva un humano (mando/teclado); false = lo juega una IA (demo).
@export var jugador_es_humano: bool = true
## Si > 0, el partido termina (y se cierra el juego) al llegar a esta cantidad de puntos jugados. Para grabar demos.
@export var salir_tras_puntos: int = 0
@export var semilla: int = 1
@export var pausa_punto: float = 1.7
@export var tiempo_preparar: float = 0.9

@onready var pista: Pista = $Pista
@onready var bola: Bola = $Bola
@onready var jugador: Personaje = $Jugador
@onready var rival: Personaje = $Rival
@onready var efectos: EfectosGolpe = $Efectos
@onready var camara: CamaraFeel = $Camara
@onready var _etiqueta_marcador: Label = $UI/Marcador
@onready var _etiqueta_mensaje: Label = $UI/Mensaje
@onready var _entrada_humana: EntradaHumana = $Jugador/EntradaHumana
@onready var _ia_jugador: ControlIA = $Jugador/ControlIA
@onready var _ia_rival: ControlIA = $Rival/ControlIA

var fase: Fases.Fase = Fases.Fase.PREPARANDO
var servidor: Personaje.Lado = Personaje.Lado.ABAJO
## Puntos por lado: índice = Personaje.Lado.
var puntos: Array[int] = [0, 0]
var golpes_en_punto: int = 0
var historial: Array = []

var _t_fase: float = 0.0
var _total_puntos: int = 0


func _ready() -> void:
	bola.pista = pista
	jugador.configurar(pista, bola, semilla * 7 + 1)
	rival.configurar(pista, bola, semilla * 7 + 2)
	_entrada_humana.configurar(jugador)
	_entrada_humana.activo = jugador_es_humano
	_ia_jugador.configurar(jugador, rival, self, bola, pista, semilla * 7 + 3)
	_ia_jugador.activo = not jugador_es_humano
	_ia_rival.configurar(rival, jugador, self, bola, pista, semilla * 7 + 4)
	efectos.camara = camara
	efectos.conectar([jugador, rival], bola, pista)
	bola.rebote.connect(_on_rebote)
	bola.golpeo_red.connect(_on_red)
	jugador.golpe_realizado.connect(_on_golpe)
	rival.golpe_realizado.connect(_on_golpe)
	_actualizar_marcador()
	_preparar_saque()


func _physics_process(delta: float) -> void:
	match fase:
		Fases.Fase.PREPARANDO:
			_t_fase -= delta
			if _t_fase <= 0.0:
				_iniciar_saque()
		Fases.Fase.PUNTO:
			_t_fase -= delta
			if _t_fase <= 0.0:
				if salir_tras_puntos > 0 and _total_puntos >= salir_tras_puntos:
					get_tree().quit()
				elif _total_puntos > 0 and maxi(puntos[0], puntos[1]) >= puntos_para_ganar:
					fase = Fases.Fase.FIN
				else:
					_preparar_saque()


func _preparar_saque() -> void:
	fase = Fases.Fase.PREPARANDO
	_t_fase = tiempo_preparar
	_etiqueta_mensaje.text = ""
	bola.parar()
	bola.visible = false
	bola.ultimo_golpeador = Personaje.NINGUNO
	golpes_en_punto = 0
	servidor = ((primer_servidor + _total_puntos / saque_cada) % 2) as Personaje.Lado
	var rect: Rect2 = pista.rect_juego()
	var centro: float = rect.position.x + rect.size.x * 0.5
	var desplazamiento: float = 28.0 if _total_puntos % 2 == 0 else -28.0
	var y_red: float = pista.y_red()
	for p: Personaje in [jugador, rival]:
		p.golpes_habilitados = false
		p.estado = Personaje.Estado.LIBRE
		# El de arriba se queda más pegado a la línea de fondo para no salirse de pantalla.
		var detras: float = rect.size.y * 0.5 + 6.0
		if p.lado == Personaje.Lado.ABAJO and p.lado == servidor:
			detras = rect.size.y * 0.5 + 12.0
		var sentido: float = 1.0 if p.lado == Personaje.Lado.ABAJO else -1.0
		var x: float = centro + (desplazamiento if p.lado == servidor else -desplazamiento)
		p.set_auto(Vector2(x, y_red + sentido * detras))
		p.mirando_derecha = true


func _iniciar_saque() -> void:
	fase = Fases.Fase.SAQUE
	for p: Personaje in [jugador, rival]:
		p.golpes_habilitados = true
		p.auto_activo = false
		p.vel = Vector2.ZERO
	var quien: Personaje = jugador if servidor == Personaje.Lado.ABAJO else rival
	quien.empezar_saque()


func _on_golpe(info: Dictionary) -> void:
	if fase == Fases.Fase.SAQUE and info["saque"]:
		fase = Fases.Fase.JUEGO
	golpes_en_punto += 1


func _on_rebote(punto: Vector2, numero: int) -> void:
	if fase == Fases.Fase.SAQUE and bola.ultimo_golpeador == Personaje.NINGUNO:
		# El lanzamiento del saque botó sin golpearlo: se repite sin penalizar.
		bola.parar()
		bola.visible = false
		var quien: Personaje = jugador if servidor == Personaje.Lado.ABAJO else rival
		quien.empezar_saque()
		return
	if fase != Fases.Fase.JUEGO:
		return
	var golpeador: int = bola.ultimo_golpeador
	var otro: int = 1 - golpeador
	var mitad: int = Personaje.Lado.ARRIBA if punto.y < pista.y_red() else Personaje.Lado.ABAJO
	if numero == 1:
		if mitad == golpeador:
			_ganar_punto(otro, "bote en su campo")
		elif not pista.contiene(punto):
			_ganar_punto(otro, "fuera")
	elif numero >= 2:
		_ganar_punto(golpeador, "doble bote")


func _on_red() -> void:
	if fase == Fases.Fase.JUEGO:
		_ganar_punto(1 - bola.ultimo_golpeador, "red")


func _ganar_punto(lado: int, motivo: String) -> void:
	if fase != Fases.Fase.JUEGO:
		return
	fase = Fases.Fase.PUNTO
	puntos[lado] += 1
	_total_puntos += 1
	_t_fase = pausa_punto
	historial.append({"ganador": lado, "motivo": motivo, "golpes": golpes_en_punto})
	_etiqueta_mensaje.text = "PUNTO" if lado == Personaje.Lado.ABAJO else "PUNTO RIVAL"
	for p: Personaje in [jugador, rival]:
		p.golpes_habilitados = false
	_actualizar_marcador()
	punto_ganado.emit(lado, motivo)
	if maxi(puntos[0], puntos[1]) >= puntos_para_ganar:
		partido_terminado.emit(lado)


func _actualizar_marcador() -> void:
	_etiqueta_marcador.text = "RIVAL %d - %d TÚ" % [puntos[Personaje.Lado.ARRIBA], puntos[Personaje.Lado.ABAJO]]
