class_name Bola
extends Node2D
## Lógica de la bola: posición en el suelo (position), altura z y velocidades.
## Trayectoria analítica (parábola + rebote), sin física del motor, para que el marcador
## de caída sea exacto y la IA pueda predecir. Lo visual está en BolaVisual.

signal lanzada(origen: Vector2)
## Rebote en el suelo. `punto` es la posición exacta del bote.
signal rebote(punto: Vector2, numero: int)
signal cruzo_red(hacia_abajo: bool)
signal golpeo_red()
signal detenida()

@export var params: ParametrosBola

var pista: Pista
var z: float = 0.0
var vel: Vector2 = Vector2.ZERO
var vz: float = 0.0
var activa: bool = false
var rebotes: int = 0
## Potencia 0-1 del último golpe (color, empuje, knockup).
var potencia: float = 0.0
## Segundos desde el último golpe.
var tiempo_vuelo: float = 0.0
var rodando: bool = false
## Lado (Personaje.Lado) de quien la golpeó por última vez; -1 si nadie (p. ej. al lanzar al aire en el saque).
var ultimo_golpeador: int = -1


## Lanza la bola con velocidades explícitas.
func lanzar(origen: Vector2, altura: float, velocidad: Vector2, velocidad_z: float, pot: float = 0.0) -> void:
	position = origen
	z = altura
	vel = velocidad
	vz = velocidad_z
	potencia = pot
	rebotes = 0
	tiempo_vuelo = 0.0
	rodando = false
	activa = true
	visible = true
	reset_physics_interpolation()
	lanzada.emit(origen)


## Lanza la bola calculando las velocidades para que bote en `destino` tras `tiempo` segundos.
func lanzar_hacia(origen: Vector2, altura: float, destino: Vector2, tiempo: float, pot: float = 0.0) -> void:
	var g: float = params.gravedad
	var velocidad: Vector2 = (destino - origen) / tiempo
	var velocidad_z: float = (0.5 * g * tiempo * tiempo - altura) / tiempo
	lanzar(origen, altura, velocidad, velocidad_z, pot)


## Predicción de la trayectoria con la física actual (sin red). Devuelve muestras
## {t, pos, z, rebotes} cada `paso` segundos. La IA la usa igual que el ojo humano: es lo que se ve.
func trayectoria_prevista(duracion: float, paso: float) -> Array:
	var res: Array = []
	var p: Vector2 = position
	var zz: float = z
	var v: Vector2 = vel
	var vzz: float = vz
	var roda: bool = rodando
	var reb: int = rebotes
	var g: float = params.gravedad
	var t: float = 0.0
	while t < duracion:
		var restante: float = paso
		var seguridad: int = 6
		while restante > 0.0 and seguridad > 0:
			seguridad -= 1
			var t_suelo: float = INF
			if not roda:
				t_suelo = (vzz + sqrt(vzz * vzz + 2.0 * g * maxf(zz, 0.0))) / g
			if t_suelo <= restante:
				p += v * t_suelo
				vzz -= g * t_suelo
				zz = 0.0
				reb += 1
				var vz_nueva: float = -vzz * params.restitucion
				v *= params.friccion_rebote
				if vz_nueva < params.velocidad_minima_rebote:
					vzz = 0.0
					roda = true
				else:
					vzz = vz_nueva
				restante -= t_suelo
			elif roda:
				p += v * restante
				v *= exp(-params.friccion_rodar * restante)
				restante = 0.0
			else:
				zz += vzz * restante - 0.5 * g * restante * restante
				vzz -= g * restante
				p += v * restante
				restante = 0.0
		t += paso
		res.append({"t": t, "pos": p, "z": zz, "rebotes": reb})
	return res


## Segundos hasta tocar el suelo con el estado actual.
func tiempo_hasta_suelo() -> float:
	if rodando:
		return 0.0
	var g: float = params.gravedad
	return (vz + sqrt(vz * vz + 2.0 * g * maxf(z, 0.0))) / g


## Punto del suelo donde botará (primer bote) con el estado actual.
func punto_aterrizaje() -> Vector2:
	return position + vel * tiempo_hasta_suelo()


func _physics_process(delta: float) -> void:
	if not activa:
		return
	_paso(delta)
	if activa and tiempo_vuelo > params.tiempo_maximo:
		_detener()


func _paso(dt: float) -> void:
	var restante: float = dt
	var seguridad: int = 6
	while restante > 0.0 and activa and seguridad > 0:
		seguridad -= 1
		var t_suelo: float = INF if rodando else tiempo_hasta_suelo()
		if t_suelo <= restante:
			# Avanza hasta el instante exacto del bote y sigue con lo que quede del paso.
			_mover(t_suelo)
			z = 0.0
			_rebotar()
			restante -= t_suelo
		else:
			_mover(restante)
			restante = 0.0


func _mover(t: float) -> void:
	var pos_previa: Vector2 = position
	var z_previa: float = z
	if rodando:
		position += vel * t
		vel *= exp(-params.friccion_rodar * t)
		if vel.length() < params.velocidad_parada:
			_detener()
	else:
		var g: float = params.gravedad
		z += vz * t - 0.5 * g * t * t
		vz -= g * t
		position += vel * t
	tiempo_vuelo += t
	_comprobar_red(pos_previa, z_previa)


func _comprobar_red(pos_previa: Vector2, z_previa: float) -> void:
	if pista == null:
		return
	var y_red: float = pista.y_red()
	var d_previa: float = pos_previa.y - y_red
	var d_actual: float = position.y - y_red
	if d_previa * d_actual >= 0.0:
		return
	var fraccion: float = d_previa / (d_previa - d_actual)
	var z_red: float = lerpf(z_previa, z, fraccion)
	if z_red < pista.alto_red:
		# Choca con la cinta: se queda en el lado de donde venía y casi sin velocidad.
		var lado: float = signf(d_previa)
		position = Vector2(lerpf(pos_previa.x, position.x, fraccion), y_red + lado * 0.5)
		z = maxf(z_red, 0.0)
		vel = Vector2(vel.x, -vel.y) * params.factor_red
		golpeo_red.emit()
	else:
		cruzo_red.emit(vel.y > 0.0)


func _rebotar() -> void:
	rebotes += 1
	var vz_nueva: float = -vz * params.restitucion
	vel *= params.friccion_rebote
	if vz_nueva < params.velocidad_minima_rebote:
		vz = 0.0
		rodando = true
	else:
		vz = vz_nueva
	rebote.emit(position, rebotes)


## Detiene la bola (se queda donde está) sin emitir `detenida`.
func parar() -> void:
	activa = false
	vel = Vector2.ZERO
	vz = 0.0


func _detener() -> void:
	if not activa:
		return
	activa = false
	vel = Vector2.ZERO
	vz = 0.0
	detenida.emit()
