class_name ControlIA
extends Node
## Controlador de IA: da órdenes (Intencion) a un Personaje igual que un mando.
## Reglas de justicia (GDD §9): no lee el input del rival, solo la trayectoria de la bola
## (visible), reacciona con retraso, comete errores y usa los mismos cooldowns que cualquiera.

@export var activo: bool = true
@export var params: ParametrosIA
## Imprime en la consola lo que decide la IA (para ajustarla).
@export var depurar: bool = false

var personaje: Personaje
var oponente: Personaje
var partido: Node
var bola: Bola
var pista: Pista

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _reloj: float = 0.0
var _fase_previa: int = -1
var _ultimo_visto: int = -2
var _t_desde_golpe: float = 0.0
var _plan: bool = false
var _ya_planeado: bool = false
var _es_saque_actual: bool = false
var _objetivo: Vector2 = Vector2.ZERO
var _t_contacto: float = 0.0
var _swing_decidido: bool = false
var _globo: bool = false
var _err_t: float = 0.0
var _t_saque: float = 0.0


func configurar(p: Personaje, o: Personaje, part: Node, b: Bola, pi: Pista, semilla: int) -> void:
	personaje = p
	oponente = o
	partido = part
	bola = b
	pista = pi
	_rng.seed = semilla
	process_physics_priority = -10


func _physics_process(delta: float) -> void:
	if not activo or personaje == null or partido == null:
		return
	_reloj += delta
	var fase: int = partido.fase
	if fase != _fase_previa:
		_fase_previa = fase
		_plan = false
		_swing_decidido = false
		_t_saque = 0.0
		_ultimo_visto = -2
	match fase:
		Fases.Fase.SAQUE:
			_saque(delta)
		Fases.Fase.JUEGO:
			_juego(delta)
		_:
			personaje.intencion.mover = Vector2.ZERO


# ---------------------------------------------------------------- saque

func _saque(delta: float) -> void:
	var i: Intencion = personaje.intencion
	i.mover = Vector2.ZERO
	if partido.servidor != personaje.lado:
		return
	_t_saque += delta
	if not personaje.saque_lanzado:
		_swing_decidido = false
		if _t_saque >= params.pausa_saque:
			i.golpear = true
			_t_saque = 0.0
			_err_t = _rng.randfn(0.0, params.error_timing_saque)
	elif not _swing_decidido:
		var p: ParametrosPersonaje = personaje.params
		var t_pico: float = maxf(bola.vz, 0.0) / bola.params.gravedad
		if t_pico <= p.arranque + p.activa * 0.5 + _err_t:
			_swing_decidido = true
			_es_saque_actual = true
			_preparar_apuntado()
			_es_saque_actual = false
			i.golpear = true


# ---------------------------------------------------------------- juego

func _juego(delta: float) -> void:
	var i: Intencion = personaje.intencion
	if bola.ultimo_golpeador != _ultimo_visto:
		_ultimo_visto = bola.ultimo_golpeador
		_t_desde_golpe = 0.0
		_plan = false
		_ya_planeado = false
		_swing_decidido = false
	_t_desde_golpe += delta
	var entrante: bool = bola.activa and bola.ultimo_golpeador != personaje.lado \
			and bola.ultimo_golpeador != Personaje.NINGUNO
	if entrante:
		if not _plan and not _ya_planeado and _t_desde_golpe >= params.reaccion:
			_ya_planeado = true
			_planificar()
		if _plan:
			_ejecutar_plan()
		else:
			_ir_a(_posicion_base())
	else:
		_ir_a(_posicion_base())
	if _plan and _reloj - _t_contacto > 0.3:
		_plan = false


func _en_mi_mitad(p: Vector2) -> bool:
	var y_red: float = pista.y_red()
	return p.y > y_red if personaje.lado == Personaje.Lado.ABAJO else p.y < y_red


func _planificar() -> void:
	var muestras: Array = bola.trayectoria_prevista(3.0, 1.0 / 60.0)
	var p: ParametrosPersonaje = personaje.params
	var y_red: float = pista.y_red()
	var idx_bote: int = -1
	for k in muestras.size():
		if muestras[k]["rebotes"] >= 1:
			idx_bote = k
			break
	if idx_bote < 0:
		return
	var pos_bote: Vector2 = muestras[idx_bote]["pos"]
	if not _en_mi_mitad(pos_bote):
		return
	if not pista.contiene(pos_bote) and _rng.randf() < params.prob_dejar_pasar:
		return
	var elegido: int = -1
	# Parry: volea antes del bote, cerca de la red.
	if _rng.randf() < params.agresividad:
		for k in idx_bote:
			var m: Dictionary = muestras[k]
			if _en_mi_mitad(m["pos"]) and m["z"] <= 40.0 and m["z"] >= 6.0 \
					and absf(m["pos"].y - y_red) <= p.zona_parry - 6.0 and m["t"] > 0.08:
				elegido = k
				break
	if elegido < 0:
		var t_obj: float = muestras[idx_bote]["t"] + params.retraso_post_rebote
		for k in range(idx_bote, muestras.size()):
			if muestras[k]["t"] >= t_obj:
				elegido = k
				break
	if elegido < 0:
		return
	var m2: Dictionary = muestras[elegido]
	_objetivo = m2["pos"] + Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * params.error_posicion
	_t_contacto = _reloj + m2["t"]
	_plan = true
	_swing_decidido = false
	_err_t = _rng.randfn(0.0, params.error_timing)
	_globo = _decidir_globo()
	if depurar:
		print("IA lado=%d planifica: objetivo=%s desde %s dist=%.0f en %.2fs volea=%s" % [personaje.lado, _objetivo, personaje.position, _objetivo.distance_to(personaje.position), m2["t"], elegido < idx_bote])


func _ejecutar_plan() -> void:
	var i: Intencion = personaje.intencion
	var p: ParametrosPersonaje = personaje.params
	var restante: float = _t_contacto - _reloj
	var d: Vector2 = _objetivo - personaje.position
	var dist: float = d.length()
	i.mover = d.normalized() * clampf(dist / 8.0, 0.0, 1.0)
	var corriendo: float = p.velocidad_max * maxf(restante - 0.03, 0.0)
	if params.usa_dash and personaje.puede_rodar() and dist > corriendo * 0.9 and dist > 16.0 \
			and dist < corriendo + p.rodar_distancia and restante > 0.12:
		i.dash = true
		i.mover = d.normalized()
	elif params.usa_plancha and personaje.puede_plancha() and restante < 0.34 and restante > 0.06 \
			and dist > p.radio_contacto + 4.0 and dist < p.plancha_distancia * 0.8 + p.radio_contacto:
		i.plancha = true
		i.mover = d.normalized()
		_swing_decidido = true
	if not _swing_decidido and personaje.estado == Personaje.Estado.LIBRE \
			and restante <= p.arranque + p.activa * 0.5 + _err_t:
		_swing_decidido = true
		_preparar_apuntado()
		if _globo:
			i.globo = true
		else:
			i.golpear = true


func _decidir_globo() -> bool:
	var cerca_red: bool = absf(oponente.position.y - pista.y_red()) < 50.0
	return _rng.randf() < (0.55 if cerca_red else params.prob_globo)


func _preparar_apuntado() -> void:
	var i: Intencion = personaje.intencion
	var rect: Rect2 = pista.rect_juego()
	var centro: float = rect.position.x + rect.size.x * 0.5
	var libre: float = signf(centro - oponente.position.x)
	if libre == 0.0:
		libre = 1.0 if _rng.randf() < 0.5 else -1.0
	var ax: float = libre * _rng.randf_range(0.35, 1.0)
	if _es_saque_actual:
		ax = libre * _rng.randf_range(0.1, 0.55)
	if _rng.randf() > params.variedad:
		ax = _rng.randf_range(-1.0, 1.0)
	var prof: float = _rng.randf_range(0.25, 1.0)
	if _es_saque_actual:
		prof = _rng.randf_range(0.3, 0.8)
	if _rng.randf() < params.prob_dejada and not _es_saque_actual:
		prof = -0.8
	i.apuntar = Vector2(ax, -prof if personaje.lado == Personaje.Lado.ABAJO else prof)


func _posicion_base() -> Vector2:
	var rect: Rect2 = pista.rect_juego()
	return Vector2(rect.position.x + rect.size.x * 0.5, pista.y_red() - personaje.adelante() * params.distancia_base)


func _ir_a(destino: Vector2) -> void:
	var d: Vector2 = destino - personaje.position
	personaje.intencion.mover = d.normalized() * clampf(d.length() / 10.0, 0.0, 1.0)
