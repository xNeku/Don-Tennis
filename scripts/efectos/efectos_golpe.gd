class_name EfectosGolpe
extends Node2D
## Game feel del golpe (GDD §12): hitstop, sacudida, destello, polvo y estela. Sin textos de aviso.
## Solo escucha los eventos de la lógica (golpe, polvo, knockup...); nunca decide nada.
## Todo es temporal y se crea por código a propósito.

@export var rampa: RampaPotencia
@export var camara: CamaraFeel

@export_group("Hitstop (segundos)")
@export var hitstop_fuerte: float = 0.04
@export var hitstop_perfecto: float = 0.07
@export var hitstop_parry: float = 0.09
@export var hitstop_knockup: float = 0.13
@export var hitstop_saque_perfecto: float = 0.06
## Potencia a partir de la cual un golpe normal ya tiene hitstop.
@export var potencia_fuerte: float = 0.6

@export_group("Sacudida")
@export var sacudida_por_potencia: float = 3.5
@export var sacudida_knockup: float = 4.0

@export_group("Sprites provisionales")
## Destellos de mayor a menor (se muestran en secuencia).
@export var destellos: Array[Texture2D] = []
@export var textura_polvo: Texture2D
## Rachas de velocidad: [horizontal, vertical].
@export var rachas: Array[Texture2D] = []

@export_group("Velocidad")
## Velocidad (unidades/s) a partir de la cual un personaje deja rachas de velocidad.
@export var velocidad_rachas: float = 78.0

## Verdadero mientras dura un hitstop (el menú de pausa no debe quitar la pausa en ese momento).
static var hitstop_activo: bool = false

var _pista: Pista
var _bola: Bola
var _cuerpo_bola: Sprite2D
var _personajes: Array = []
var _hitstop: float = 0.0
var _tick: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 5


func conectar(personajes: Array, b: Bola, p: Pista) -> void:
	_bola = b
	_pista = p
	_cuerpo_bola = b.get_node("Visual/Cuerpo") as Sprite2D
	_personajes = personajes
	b.rebote.connect(_on_rebote_bola)
	for per: Personaje in personajes:
		per.golpe_realizado.connect(_on_golpe)
		per.polvo.connect(_on_polvo.bind(per))
		per.knockup_iniciado.connect(_on_knockup.bind(per))
		per.plancha_iniciada.connect(_on_plancha.bind(per))


func _exit_tree() -> void:
	hitstop_activo = false


func _process(delta: float) -> void:
	if _hitstop > 0.0:
		_hitstop -= delta
		if _hitstop <= 0.0:
			hitstop_activo = false
			if not MenuPausa.abierto:
				get_tree().paused = false


func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return
	_tick += 1
	_rachas_de_velocidad()
	_estela_bola()


# Rachas cortas detrás de quien corre a toda velocidad (el suelo "se lleva" el movimiento).
func _rachas_de_velocidad() -> void:
	if rachas.size() < 2 or _tick % 3 != 0 or _pista == null:
		return
	for per: Personaje in _personajes:
		var v: Vector2 = per.vel
		var rapidez: float = v.length()
		if rapidez < velocidad_rachas or per.estado != Personaje.Estado.LIBRE or per.derrapando:
			continue
		var horizontal: bool = absf(v.x) >= absf(v.y)
		var racha: Sprite2D = Sprite2D.new()
		racha.texture = rachas[0] if horizontal else rachas[1]
		var pie: Vector2 = _pista.proyectar(per.position).round()
		var atras: Vector2 = -v.normalized()
		racha.position = (pie + Vector2(atras.x * 10.0, atras.y * 7.0 - 4.0 + _rng.randf_range(-3.0, 3.0))).round()
		racha.modulate = Color(1, 1, 1, clampf((rapidez - velocidad_rachas) / 40.0 + 0.35, 0.35, 0.8))
		add_child(racha)
		var tween: Tween = create_tween()
		tween.tween_property(racha, "modulate:a", 0.0, 0.2)
		tween.tween_callback(racha.queue_free)


func _estela_bola() -> void:
	# Estela de la bola cuando va potente.
	if _bola == null or not _bola.activa or _bola.rodando or _bola.potencia < 0.5:
		return
	if _tick % 2 != 0:
		return
	var rastro: Sprite2D = Sprite2D.new()
	rastro.texture = _cuerpo_bola.texture
	rastro.global_position = _cuerpo_bola.global_position.round()
	rastro.modulate = rampa.color_para(_bola.potencia) if rampa != null else Color.WHITE
	rastro.modulate.a = 0.6
	add_child(rastro)
	var tween: Tween = create_tween()
	tween.tween_property(rastro, "modulate:a", 0.0, 0.16)
	tween.tween_callback(rastro.queue_free)


func _pedir_hitstop(duracion: float) -> void:
	if duracion > _hitstop:
		_hitstop = duracion
		hitstop_activo = true
		get_tree().paused = true


func _on_golpe(info: Dictionary) -> void:
	var potencia: float = info["potencia"]
	var pantalla: Vector2 = _pista.proyectar(info["pos"], info["z"]).round()
	var perfecto: bool = info["perfecto"]
	var parry: bool = info["parry"]
	var nivel: int = rampa.nivel(potencia) if rampa != null else 0

	# Hitstop: lo más importante manda.
	if info["knock"]:
		_pedir_hitstop(hitstop_knockup)
	elif parry:
		_pedir_hitstop(hitstop_parry)
	elif perfecto:
		_pedir_hitstop(hitstop_saque_perfecto if info["saque"] else hitstop_perfecto)
	elif potencia >= potencia_fuerte:
		_pedir_hitstop(hitstop_fuerte)

	if camara != null:
		var fuerza: float = potencia * sacudida_por_potencia
		if info["knock"]:
			fuerza = sacudida_knockup
		if fuerza >= 1.0:
			camara.sacudir(fuerza, 0.12 + 0.22 * potencia)

	if nivel >= 1 or perfecto or parry:
		_destello(pantalla, nivel)


# Polvo en el bote: más cuanto más potente y rápida va la bola.
func _on_rebote_bola(punto: Vector2, _numero: int) -> void:
	var rapidez: float = _bola.vel.length()
	if _bola.potencia < 0.3 and rapidez < 170.0:
		return
	_on_polvo(punto, 1 + int(_bola.potencia * 4.0) + int(rapidez / 220.0))


func _on_knockup(_per: Personaje) -> void:
	pass


func _on_plancha(_per: Personaje) -> void:
	pass


func _destello(pos: Vector2, nivel: int) -> void:
	if destellos.is_empty():
		return
	var spr: Sprite2D = Sprite2D.new()
	spr.position = pos
	spr.modulate = rampa.color_para(0.0 + nivel * 0.25) if rampa != null else Color.WHITE
	add_child(spr)
	var tween: Tween = create_tween()
	for tex: Texture2D in destellos:
		tween.tween_callback(spr.set_texture.bind(tex))
		tween.tween_interval(0.035)
	tween.tween_callback(spr.queue_free)
	spr.texture = destellos[0]


func _on_polvo(pos: Vector2, cantidad: int, _per: Personaje = null) -> void:
	if textura_polvo == null or _pista == null:
		return
	var base: Vector2 = _pista.proyectar(pos).round()
	for i in cantidad:
		var particula: Sprite2D = Sprite2D.new()
		particula.texture = textura_polvo
		particula.position = base + Vector2(_rng.randf_range(-4.0, 4.0), -1.0)
		particula.modulate = Color(0.9, 0.88, 0.78, 0.9)
		add_child(particula)
		var destino: Vector2 = particula.position + Vector2(_rng.randf_range(-12.0, 12.0), _rng.randf_range(-9.0, -2.0))
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particula, "position", destino, 0.35)
		tween.tween_property(particula, "modulate:a", 0.0, 0.35)
		tween.chain().tween_callback(particula.queue_free)
