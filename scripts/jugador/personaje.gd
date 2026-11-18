class_name Personaje
extends Node2D
## Lógica de un jugador (humano, IA o rival: las reglas son las mismas para todos).
## `position` está en coordenadas LÓGICAS de pista. Lo visual vive en PersonajeVisual.
## Recibe órdenes por `intencion` (Intencion) y emite eventos que escuchan los efectos.

enum Lado { ARRIBA, ABAJO }
enum Estado { LIBRE, SAQUE, GOLPE, RODAR, PLANCHA, TIRADO, KNOCKUP }

## Se emite al devolver la bola. `info`: personaje, pos, z, perfecto, parry, potencia, entrante,
## saque, emergencia, knock, destino.
signal golpe_realizado(info: Dictionary)
## Nube de polvo en una posición lógica.
signal polvo(pos: Vector2, cantidad: int)
signal rodar_iniciado()
signal plancha_iniciada()
signal plancha_terminada(acierto: bool)
signal knockup_iniciado()
## Cambio brusco de sentido a velocidad: el personaje derrapa y pierde unas décimas.
signal derrape_iniciado()

const NINGUNO: int = -1

@export var params: ParametrosPersonaje
@export var lado: Lado = Lado.ABAJO
## Animaciones y sombra de este personaje (los lee PersonajeVisual).
@export var hoja: HojaAnimaciones
@export var sombra: Texture2D

var intencion: Intencion = Intencion.new()
var pista: Pista
var bola: Bola

var estado: Estado = Estado.LIBRE
var vel: Vector2 = Vector2.ZERO
var mirando_derecha: bool = true
var saque_lanzado: bool = false
## Mientras sea false no se puede golpear (entre puntos).
var golpes_habilitados: bool = true
var auto_activo: bool = false
var auto_destino: Vector2 = Vector2.ZERO
## Progreso 0-1 del estado actual (para animar).
var progreso: float = 0.0
var swing_globo: bool = false
var swing_saque: bool = false
var swing_conectado: bool = false
var cooldown_rodar: float = 0.0
var cooldown_plancha: float = 0.0
## Verdadero mientras derrapa tras un cambio brusco de sentido.
var derrapando: bool = false

var _swing_t: float = 0.0
var _tiempo_estado: float = 0.0
var _duracion_estado: float = 0.0
var _dir_accion: Vector2 = Vector2.ZERO
var _plancha_acierto: bool = false
var _t_polvo: float = 0.0
var _derrape_t: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func configurar(p: Pista, b: Bola, semilla: int) -> void:
	pista = p
	bola = b
	_rng.seed = semilla


## +1 si el rival está hacia +y (soy el de arriba), -1 si está hacia -y (soy el de abajo).
func adelante() -> float:
	return -1.0 if lado == Lado.ABAJO else 1.0


func puede_rodar() -> bool:
	return estado == Estado.LIBRE and cooldown_rodar <= 0.0 and not auto_activo


func puede_plancha() -> bool:
	return estado == Estado.LIBRE and cooldown_plancha <= 0.0 and not auto_activo


func poner_en(pos: Vector2) -> void:
	position = pos
	vel = Vector2.ZERO
	estado = Estado.LIBRE


func set_auto(destino: Vector2) -> void:
	auto_activo = true
	auto_destino = destino


func empezar_saque() -> void:
	auto_activo = false
	estado = Estado.SAQUE
	saque_lanzado = false
	vel = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if pista == null:
		return
	cooldown_rodar = maxf(cooldown_rodar - delta, 0.0)
	cooldown_plancha = maxf(cooldown_plancha - delta, 0.0)
	_t_polvo = maxf(_t_polvo - delta, 0.0)
	match estado:
		Estado.LIBRE:
			_libre(delta)
		Estado.SAQUE:
			_saque(delta)
		Estado.GOLPE:
			_golpe(delta)
		Estado.RODAR:
			_rodar(delta)
		Estado.PLANCHA:
			_plancha(delta)
		Estado.TIRADO:
			_tirado(delta)
		Estado.KNOCKUP:
			_knockup(delta)
	_limitar_posicion()
	intencion.limpiar_pulsos()


# ---------------------------------------------------------------- estados

func _libre(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	if auto_activo:
		var d: Vector2 = auto_destino - position
		dir = d.normalized() * clampf(d.length() / 8.0, 0.0, 1.0)
	else:
		dir = intencion.mover
		if dir.length() > 1.0:
			dir = dir.normalized()
	_mover_libre(dir, 1.0, delta, true)
	if auto_activo or not golpes_habilitados:
		return
	if intencion.golpear:
		_empezar_golpe(false, false)
	elif intencion.globo:
		_empezar_golpe(true, false)
	elif intencion.dash and cooldown_rodar <= 0.0:
		_empezar_rodar(dir)
	elif intencion.plancha and cooldown_plancha <= 0.0:
		_empezar_plancha(dir)


func _mover_libre(dir: Vector2, factor: float, delta: float, girar: bool) -> void:
	var rapidez: float = vel.length()
	# Agarre del suelo (fricción de la pista): más agarre = acelera, frena y gira antes.
	var agarre: float = pista.friccion_jugador
	# Cambio brusco de sentido a velocidad: derrape (peso del personaje).
	if _derrape_t <= 0.0 and not auto_activo and dir.length() > 0.3 \
			and rapidez >= params.derrape_velocidad_min and vel.normalized().dot(dir.normalized()) < -0.35:
		_derrape_t = params.derrape_duracion * clampf(rapidez / params.velocidad_max, 0.0, 1.0) / agarre
		polvo.emit(position, 6)
		_t_polvo = 0.06
		derrape_iniciado.emit()
	derrapando = _derrape_t > 0.0
	if derrapando:
		_derrape_t -= delta
		# Desliza: fricción fuerte sobre el movimiento anterior y poco control hacia el nuevo sentido.
		vel = vel.move_toward(Vector2.ZERO, params.derrape_friccion * agarre * delta)
		if dir.length() > 0.1:
			vel += dir * params.aceleracion * agarre * params.derrape_control * delta
		if _t_polvo <= 0.0:
			polvo.emit(position, 2)
			_t_polvo = 0.06
		position += vel * delta
		if girar and absf(vel.x) > 12.0:
			mirando_derecha = vel.x > 0.0
		return
	var objetivo: Vector2 = dir * params.velocidad_max * factor
	var aceleracion: float = (params.aceleracion if dir.length() > 0.1 else params.deceleracion) * agarre
	if dir.length() <= 0.1 and rapidez > 85.0 and _t_polvo <= 0.0:
		# Frenazo en seco desde la carrera.
		polvo.emit(position, 3)
		_t_polvo = 0.2
	elif rapidez > 55.0 and _t_polvo <= 0.0:
		# Pisadas: más polvo y más seguido cuanto más rápido corres.
		polvo.emit(position, 1 + int(rapidez / 90.0))
		_t_polvo = lerpf(0.2, 0.1, clampf(rapidez / params.velocidad_max, 0.0, 1.0))
	vel = vel.move_toward(objetivo, aceleracion * delta)
	position += vel * delta
	if girar and absf(vel.x) > 12.0:
		mirando_derecha = vel.x > 0.0


func _saque(delta: float) -> void:
	vel = vel.move_toward(Vector2.ZERO, params.deceleracion * delta)
	position += vel * delta
	if not golpes_habilitados:
		return
	if intencion.golpear:
		if not saque_lanzado:
			_lanzar_saque()
		else:
			_empezar_golpe(false, true)


func _lanzar_saque() -> void:
	var lado_x: float = 6.0 if mirando_derecha else -6.0
	bola.lanzar(Vector2(position.x + lado_x, position.y + adelante() * 3.0),
			params.saque_altura_inicial, Vector2.ZERO, params.saque_vz, 0.0)
	bola.ultimo_golpeador = NINGUNO
	saque_lanzado = true


func _empezar_golpe(globo: bool, saque: bool) -> void:
	estado = Estado.GOLPE
	_swing_t = 0.0
	swing_globo = globo
	swing_saque = saque
	swing_conectado = false
	_duracion_estado = params.arranque + params.activa + params.recuperacion
	progreso = 0.0
	if bola != null and bola.activa:
		mirando_derecha = bola.position.x >= position.x


func _golpe(delta: float) -> void:
	_swing_t += delta
	progreso = clampf(_swing_t / _duracion_estado, 0.0, 1.0)
	var dir: Vector2 = Vector2.ZERO if auto_activo else intencion.mover
	_mover_libre(dir, params.velocidad_en_golpe, delta, false)
	if not swing_conectado and _swing_t >= params.arranque and _swing_t <= params.arranque + params.activa:
		var alto: float = params.saque_altura_max_contacto if swing_saque else params.altura_max_contacto
		if _puede_alcanzar(bola, params.radio_contacto, alto):
			swing_conectado = true
			_resolver_golpe(bola, false)
	if _swing_t >= _duracion_estado:
		estado = Estado.LIBRE


func _empezar_rodar(dir: Vector2) -> void:
	_dir_accion = _direccion_accion(dir)
	estado = Estado.RODAR
	_tiempo_estado = 0.0
	_duracion_estado = params.rodar_duracion
	progreso = 0.0
	vel = Vector2.ZERO
	polvo.emit(position, 6)
	rodar_iniciado.emit()


func _rodar(delta: float) -> void:
	_tiempo_estado += delta
	progreso = clampf(_tiempo_estado / _duracion_estado, 0.0, 1.0)
	var rapidez: float = params.rodar_distancia / params.rodar_duracion * (1.8 * (1.0 - progreso) + 0.2) / 1.1
	position += _dir_accion * rapidez * delta
	if _tiempo_estado >= _duracion_estado:
		polvo.emit(position, 5)
		vel = _dir_accion * 40.0
		cooldown_rodar = params.rodar_cooldown
		estado = Estado.LIBRE


func _empezar_plancha(dir: Vector2) -> void:
	_dir_accion = _direccion_accion(dir)
	estado = Estado.PLANCHA
	_tiempo_estado = 0.0
	_duracion_estado = params.plancha_duracion
	progreso = 0.0
	_plancha_acierto = false
	vel = Vector2.ZERO
	polvo.emit(position, 4)
	plancha_iniciada.emit()


func _plancha(delta: float) -> void:
	_tiempo_estado += delta
	progreso = clampf(_tiempo_estado / _duracion_estado, 0.0, 1.0)
	var rapidez: float = params.plancha_distancia / params.plancha_duracion * (1.8 * (1.0 - progreso) + 0.2) / 1.1
	position += _dir_accion * rapidez * delta
	swing_saque = false
	if not _plancha_acierto and golpes_habilitados \
			and _puede_alcanzar(bola, params.plancha_radio, params.plancha_altura_max):
		_plancha_acierto = true
		_resolver_golpe(bola, true)
	if _tiempo_estado >= _duracion_estado:
		polvo.emit(position, 8)
		estado = Estado.TIRADO
		_tiempo_estado = 0.0
		_duracion_estado = params.tirado_acierto if _plancha_acierto else params.tirado_fallo
		progreso = 0.0
		plancha_terminada.emit(_plancha_acierto)


func _tirado(delta: float) -> void:
	_tiempo_estado += delta
	progreso = clampf(_tiempo_estado / _duracion_estado, 0.0, 1.0)
	if _tiempo_estado >= _duracion_estado:
		cooldown_plancha = params.plancha_cooldown
		estado = Estado.LIBRE


func _empezar_knockup() -> void:
	estado = Estado.KNOCKUP
	_tiempo_estado = 0.0
	_duracion_estado = params.knockup_duracion
	progreso = 0.0
	vel = Vector2.ZERO
	_dir_accion = Vector2(0.0, -adelante())
	knockup_iniciado.emit()


func _knockup(delta: float) -> void:
	var antes: float = _tiempo_estado
	_tiempo_estado += delta
	progreso = clampf(_tiempo_estado / _duracion_estado, 0.0, 1.0)
	const VUELO: float = 0.35
	if _tiempo_estado < VUELO:
		position += _dir_accion * params.knockup_distancia / VUELO * 2.0 * (1.0 - _tiempo_estado / VUELO) * delta
	elif antes < VUELO:
		polvo.emit(position, 8)
	if _tiempo_estado >= _duracion_estado:
		estado = Estado.LIBRE


# ---------------------------------------------------------------- golpe

func _direccion_accion(dir: Vector2) -> Vector2:
	if dir.length() > 0.1:
		return dir.normalized()
	return Vector2(1.0 if mirando_derecha else -1.0, 0.0)


func _puede_alcanzar(b: Bola, radio: float, altura_max: float) -> bool:
	if b == null or not b.activa or not golpes_habilitados:
		return false
	if b.ultimo_golpeador == lado or b.rebotes >= 2:
		return false
	var y_red: float = pista.y_red()
	if lado == Lado.ABAJO and b.position.y < y_red + 2.0:
		return false
	if lado == Lado.ARRIBA and b.position.y > y_red - 2.0:
		return false
	return b.position.distance_to(position) <= radio and b.z <= altura_max


func _resolver_golpe(b: Bola, emergencia: bool) -> void:
	var y_red: float = pista.y_red()
	var error_t: float = absf((_swing_t - params.arranque) - params.activa * 0.5)
	var calidad: float = clampf(1.0 - error_t / (params.activa * 0.5), 0.0, 1.0)
	var perfecto: bool = false
	if swing_saque:
		perfecto = absf(b.vz) <= params.saque_vz_perfecto
		calidad = clampf(1.0 - absf(b.vz) / 200.0, 0.0, 1.0)
	elif not emergencia:
		perfecto = error_t <= params.ventana_perfecta
	var entrante: float = b.potencia
	var parry: bool = not swing_saque and not emergencia and b.rebotes == 0 \
			and absf(b.position.y - y_red) <= params.zona_parry
	var anula: bool = perfecto or parry
	var delante: bool = absf(position.y - y_red) <= params.zona_delantera
	var knock: bool = not anula and not emergencia and not swing_saque \
			and entrante >= params.umbral_knockup and delante

	var tipo: TipoGolpe = params.tipo_normal
	if swing_saque:
		tipo = params.tipo_saque
	elif swing_globo or emergencia:
		tipo = params.tipo_globo
	var tiempo: float = tipo.tiempo_vuelo
	var potencia: float = tipo.potencia
	if perfecto:
		tiempo *= params.factor_tiempo_perfecto
		potencia += 0.3
	if parry:
		tiempo /= params.mult_parry
		potencia += 0.25
	# El peloteo se acelera con cada golpe seguido; los globos ni se aceleran ni suben el ritmo.
	var es_globo: bool = swing_globo or emergencia
	var ritmo_golpes: int = b.golpes_en_juego
	if not es_globo and b.ritmo != null:
		tiempo *= b.ritmo.factor_tiempo(ritmo_golpes)
	if emergencia:
		potencia = 0.1
	if knock:
		tiempo = 1.1
		potencia = 0.0
	tiempo = maxf(tiempo, params.tiempo_minimo)
	potencia = clampf(potencia, 0.0, 1.0)

	# Colocación: x sale del stick; la profundidad, del stick hacia delante/atrás.
	var ap: Vector2 = intencion.apuntar
	var prof: float = -ap.y if lado == Lado.ABAJO else ap.y
	if swing_globo or emergencia:
		prof = maxf(prof, 0.5)
	if emergencia:
		ap.x *= 0.3
	if knock:
		ap = Vector2(_rng.randf_range(-1.0, 1.0), 0.0)
		prof = 0.0
	var rect: Rect2 = pista.rect_juego()
	var dist: float = lerpf(params.dist_corta, params.dist_profunda, (clampf(prof, -1.0, 1.0) + 1.0) * 0.5)
	var dispersion: float = lerpf(params.dispersion_max, 0.0, calidad)
	if emergencia:
		dispersion = params.dispersion_max * 0.6
	var destino: Vector2 = Vector2(
			rect.position.x + rect.size.x * 0.5 + clampf(ap.x, -1.0, 1.0) * params.alcance_lateral
					+ _rng.randf_range(-dispersion, dispersion),
			y_red + adelante() * dist + _rng.randf_range(-dispersion, dispersion) * 0.5)
	tiempo = Golpe.tiempo_con_red(b.params.gravedad, b.position, b.z, destino, tiempo,
			y_red, pista.alto_red, params.margen_red)

	var info: Dictionary = {
		"personaje": self, "pos": b.position, "z": b.z, "perfecto": perfecto, "parry": parry,
		"potencia": potencia, "entrante": entrante, "saque": swing_saque,
		"emergencia": emergencia, "knock": knock, "destino": destino, "globo": swing_globo or emergencia,
	}
	b.lanzar_hacia(b.position, maxf(b.z, 4.0), destino, tiempo, potencia)
	b.ultimo_golpeador = lado
	b.golpes_en_juego += 1
	if es_globo and b.ritmo != null:
		# El globo relaja el peloteo.
		b.golpes_en_juego = maxi(b.golpes_en_juego - b.ritmo.relajacion_globo, 0)

	if knock:
		_empezar_knockup()
	elif not anula and not emergencia and not swing_saque and entrante > 0.3:
		vel += Vector2(0.0, -adelante()) * entrante * params.empuje_base
	golpe_realizado.emit(info)


func _limitar_posicion() -> void:
	var rect: Rect2 = pista.rect_juego()
	var y_red: float = pista.y_red()
	position.x = clampf(position.x, rect.position.x - 16.0, rect.end.x + 16.0)
	if lado == Lado.ABAJO:
		position.y = clampf(position.y, y_red + 10.0, rect.end.y + 20.0)
	else:
		position.y = clampf(position.y, rect.position.y - 14.0, y_red - 10.0)
