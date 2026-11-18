class_name EfectosGolpe
extends Node2D
## Game feel del golpe (GDD §12): hitstop, sacudida, destello, texto flotante, polvo y estela.
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

var _pista: Pista
var _bola: Bola
var _cuerpo_bola: Sprite2D
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
	for per: Personaje in personajes:
		per.golpe_realizado.connect(_on_golpe)
		per.polvo.connect(_on_polvo.bind(per))
		per.knockup_iniciado.connect(_on_knockup.bind(per))
		per.plancha_iniciada.connect(_on_plancha.bind(per))


func _exit_tree() -> void:
	if is_inside_tree():
		get_tree().paused = false


func _process(delta: float) -> void:
	if _hitstop > 0.0:
		_hitstop -= delta
		if _hitstop <= 0.0:
			get_tree().paused = false


func _physics_process(_delta: float) -> void:
	# Estela de la bola cuando va potente.
	if get_tree().paused or _bola == null or not _bola.activa or _bola.rodando or _bola.potencia < 0.5:
		return
	_tick += 1
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

	# Textos
	var color: Color = rampa.color_para(potencia) if rampa != null else Color.WHITE
	if info["knock"]:
		_texto("KNOCKUP!", pantalla, Color(1.0, 0.35, 0.3))
	elif parry and perfecto:
		_texto("PARRY PERFECTO", pantalla, Color(0.5, 1.0, 1.0))
	elif parry:
		_texto("PARRY", pantalla, Color(0.5, 0.95, 1.0))
	elif perfecto:
		_texto("PERFECTO", pantalla, Color(1.0, 0.9, 0.35))
	elif info["emergencia"]:
		_texto("¡PLANCHA!", pantalla, Color(0.85, 0.9, 1.0))
	elif nivel >= 4:
		_texto("BRUTAL", pantalla, color)


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


func _texto(texto: String, pos: Vector2, color: Color) -> void:
	var etiqueta: Label = Label.new()
	etiqueta.text = texto
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.add_theme_font_size_override("font_size", 8)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_color_override("font_outline_color", Color("14122b"))
	etiqueta.add_theme_constant_override("outline_size", 3)
	add_child(etiqueta)
	var tam: Vector2 = etiqueta.get_minimum_size()
	etiqueta.position = Vector2(
			clampf(pos.x - tam.x * 0.5, 2.0, 478.0 - tam.x), maxf(pos.y - 22.0, 14.0)).round()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(etiqueta, "position:y", etiqueta.position.y - 14.0, 0.7)
	tween.tween_property(etiqueta, "modulate:a", 0.0, 0.25).set_delay(0.45)
	tween.chain().tween_callback(etiqueta.queue_free)


func _on_polvo(pos: Vector2, cantidad: int, _per: Personaje) -> void:
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
