class_name SonidosPartido
extends Node
## Hace sonar el banco de sonidos según los eventos de la lógica (golpes, botes, derrapes...).
## Solo escucha: nunca decide nada. Sigue sonando durante el hitstop y la pausa.

signal reproducido(id: StringName)

@export var banco: BancoSonidos
## Nº de sonidos que pueden sonar a la vez.
@export var voces: int = 14
@export var volumen_pisada_db: float = -6.0

var _jugadores: Array[AudioStreamPlayer] = []
var _siguiente: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _t_pisada: Dictionary = {}
var _bola: Bola


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 21
	for i in voces:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_jugadores.append(p)
	# Ambiente en bucle: el nodo Ambiente (si existe) se repite al acabar.
	var ambiente: AudioStreamPlayer = get_node_or_null("Ambiente") as AudioStreamPlayer
	if ambiente != null:
		ambiente.process_mode = Node.PROCESS_MODE_ALWAYS
		ambiente.finished.connect(ambiente.play)
		if ambiente.stream != null:
			ambiente.play()


func conectar(personajes: Array, b: Bola, partido: Node = null) -> void:
	_bola = b
	for per: Personaje in personajes:
		per.golpe_realizado.connect(_on_golpe)
		per.derrape_iniciado.connect(reproducir.bind(&"derrape"))
		per.rodar_iniciado.connect(reproducir.bind(&"rodar"))
		per.plancha_iniciada.connect(reproducir.bind(&"plancha"))
		per.plancha_terminada.connect(func(_acierto: bool) -> void: reproducir(&"plancha_caida"))
		per.knockup_iniciado.connect(reproducir.bind(&"knockup"))
		per.polvo.connect(_on_polvo.bind(per))
	b.rebote.connect(_on_rebote)
	b.golpeo_red.connect(reproducir.bind(&"red"))
	b.lanzada.connect(_on_lanzada)
	if partido != null and partido.has_signal("punto_ganado"):
		partido.punto_ganado.connect(_on_punto)


## Hace sonar el evento `id`. `extra_db` sube o baja el volumen; `tono` multiplica el tono.
func reproducir(id: StringName, extra_db: float = 0.0, tono: float = 1.0) -> void:
	if banco == null:
		return
	var evento: SonidoEvento = banco.buscar(id)
	if evento == null:
		return
	var stream: AudioStream = evento.elegir(_rng)
	if stream == null:
		return
	var voz: AudioStreamPlayer = _voz_libre()
	voz.stream = stream
	voz.bus = evento.bus
	voz.volume_db = evento.volumen_db + extra_db
	voz.pitch_scale = tono * (1.0 + _rng.randf_range(-evento.variacion_tono, evento.variacion_tono))
	voz.play()
	reproducido.emit(id)


func _voz_libre() -> AudioStreamPlayer:
	for v: AudioStreamPlayer in _jugadores:
		if not v.playing:
			return v
	_siguiente = (_siguiente + 1) % _jugadores.size()
	return _jugadores[_siguiente]


func _on_golpe(info: Dictionary) -> void:
	var potencia: float = info["potencia"]
	var extra: float = lerpf(-4.0, 1.0, potencia)
	var id: StringName = &"golpe_suave"
	if info["parry"]:
		id = &"parry"
	elif info["perfecto"]:
		id = &"golpe_perfecto"
	elif info["emergencia"]:
		id = &"golpe_suave"
	elif info["saque"]:
		id = &"saque"
	elif info["globo"]:
		id = &"globo"
	elif potencia >= 0.55:
		id = &"golpe_fuerte"
	reproducir(id, extra)


func _on_polvo(_pos: Vector2, cantidad: int, per: Personaje) -> void:
	# Las pisadas son el polvo pequeño de correr; derrapes, rodares y caídas ya tienen su sonido.
	if cantidad > 3 or per.derrapando or per.estado != Personaje.Estado.LIBRE:
		return
	var ahora: float = Time.get_ticks_msec() / 1000.0
	if ahora - _t_pisada.get(per, 0.0) < 0.1:
		return
	_t_pisada[per] = ahora
	reproducir(&"pisada", volumen_pisada_db)


func _on_rebote(_punto: Vector2, numero: int) -> void:
	if numero > 2:
		return
	var rapidez: float = _bola.vel.length()
	reproducir(&"bote_fuerte" if rapidez > 200.0 else &"bote_suave", clampf((rapidez - 150.0) / 120.0, -4.0, 1.0))


func _on_lanzada(_origen: Vector2) -> void:
	# Lanzar la bola al aire para sacar (nadie la ha golpeado todavía).
	if _bola.ultimo_golpeador == Personaje.NINGUNO:
		reproducir(&"saque_lanzar")


func _on_punto(lado: int, _motivo: String) -> void:
	reproducir(&"punto_ganado" if lado == Personaje.Lado.ABAJO else &"punto_perdido")
