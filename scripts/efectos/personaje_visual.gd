class_name PersonajeVisual
extends Node2D
## Parte visual de un Personaje: sprite animado (frames desde HojaAnimaciones), sombra y arco de golpe.
## Solo lee el estado del Personaje. Pixel art: sin escalar, posiciones a píxel entero.

## Color del arco según la potencia del golpe (GDD §12).
@export var rampa: RampaPotencia
## Arcos de golpe de menor a mayor tamaño (media luna que sigue a la raqueta).
@export var arcos: Array[Texture2D] = []
## Distancia (px) de la raqueta al centro del cuerpo, para colocar el arco.
@export var alcance_arco: Vector2 = Vector2(13.0, -22.0)
@export var margen_pie: int = 1

@onready var _p: Personaje = get_parent() as Personaje
@onready var _cuerpo: AnimatedSprite2D = $Cuerpo
@onready var _sombra: Sprite2D = $Sombra
@onready var _arco: Sprite2D = $Arco

var _color_arco: Color = Color(1, 1, 1)
var _destello: float = 0.0
var _alza: float = 0.0


func _ready() -> void:
	_cuerpo.sprite_frames = _p.hoja.construir_frames()
	_cuerpo.offset = Vector2(0.0, -_p.hoja.tamano_frame.y * 0.5 + margen_pie)
	_sombra.texture = _p.sombra
	_arco.visible = false
	_p.golpe_realizado.connect(_on_golpe)


func _on_golpe(info: Dictionary) -> void:
	_color_arco = rampa.color_para(info["potencia"]) if rampa != null else Color.WHITE
	if info["perfecto"] or info["parry"]:
		_destello = 0.07


func _physics_process(delta: float) -> void:
	if _p.pista == null:
		return
	global_position = _p.pista.proyectar(_p.position).round()
	_animar()
	_actualizar_arco()
	_destello = maxf(_destello - delta, 0.0)
	_cuerpo.modulate = Color(2.2, 2.2, 2.2) if _destello > 0.0 else Color.WHITE
	_cuerpo.position = Vector2(0.0, -roundf(_alza))
	_sombra.position = Vector2.ZERO


func _animar() -> void:
	_alza = 0.0
	_cuerpo.flip_h = not _p.mirando_derecha
	match _p.estado:
		Personaje.Estado.GOLPE:
			_por_progreso(&"globo" if _p.swing_globo else &"golpe", _p.progreso)
		Personaje.Estado.RODAR:
			_por_progreso(&"rodar", _p.progreso)
		Personaje.Estado.PLANCHA:
			_por_progreso(&"plancha", _p.progreso)
			_alza = sin(_p.progreso * PI) * 3.0
		Personaje.Estado.TIRADO:
			_en_bucle(&"tirado")
		Personaje.Estado.KNOCKUP:
			_por_progreso(&"knockup", minf(_p.progreso * 2.3, 1.0))
			_alza = sin(minf(_p.progreso / 0.4375, 1.0) * PI) * 14.0
		_:
			if _p.vel.length() > 14.0:
				_en_bucle(&"correr")
			else:
				_en_bucle(&"quieto")


func _en_bucle(nombre: StringName) -> void:
	if _cuerpo.animation != nombre or not _cuerpo.is_playing():
		_cuerpo.play(nombre)


func _por_progreso(nombre: StringName, progreso: float) -> void:
	if _cuerpo.is_playing():
		_cuerpo.pause()
	if _cuerpo.animation != nombre:
		_cuerpo.animation = nombre
	var total: int = _cuerpo.sprite_frames.get_frame_count(nombre)
	_cuerpo.frame = clampi(int(progreso * total), 0, total - 1)


func _actualizar_arco() -> void:
	var activo: bool = _p.estado == Personaje.Estado.GOLPE and _p.progreso > 0.2 and _p.progreso < 0.72 \
			and not arcos.is_empty()
	_arco.visible = activo
	if not activo:
		return
	var t: float = (_p.progreso - 0.2) / 0.52
	_arco.texture = arcos[mini(int(t * arcos.size()), arcos.size() - 1)]
	_arco.flip_h = not _p.mirando_derecha
	var lado: float = 1.0 if _p.mirando_derecha else -1.0
	_arco.position = Vector2(lado * alcance_arco.x, alcance_arco.y)
	_arco.modulate = _color_arco if _p.swing_conectado else Color(0.9, 0.9, 1.0, 0.7)
