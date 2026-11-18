class_name BolaVisual
extends Node2D
## Parte visual de la bola: cuerpo (con altura), sombra y marcador de caída.
## Solo lee el estado de Bola y pide a la Pista que proyecte; no decide nada de la física.
## Visual y Marcador son `top_level`: su posición en pantalla la pone la proyección.

## Segundos tras el golpe antes de que aparezca el marcador (hay que leer algo).
@export var retraso_marcador: float = 0.12
## Altura a la que la sombra alcanza su tamaño mínimo.
@export var altura_sombra_max: float = 120.0
@export var color_marcador_dentro: Color = Color(1.0, 0.82, 0.25, 1.0)
@export var color_marcador_fuera: Color = Color(0.55, 0.57, 0.65, 1.0)

@onready var _bola: Bola = get_parent() as Bola
@onready var _cuerpo: Node2D = $Cuerpo
@onready var _sombra: Node2D = $Sombra
@onready var _marcador: Node2D = $Marcador

var _marcador_visible_previo: bool = false


func _ready() -> void:
	_marcador.visible = false
	_bola.lanzada.connect(_on_lanzada)


func _on_lanzada(_origen: Vector2) -> void:
	_marcador_visible_previo = false
	_actualizar()
	reset_physics_interpolation()


# Se actualiza en _physics_process (después de la lógica, que es el padre) para que la
# interpolación de físicas suavice también la altura y el marcador.
func _physics_process(_delta: float) -> void:
	_actualizar()


func _actualizar() -> void:
	var pista: Pista = _bola.pista
	if pista == null:
		return

	global_position = pista.proyectar(_bola.position)
	scale = Vector2.ONE * pista.escala_en(_bola.position)
	_cuerpo.position = Vector2(0.0, -_bola.z * pista.factor_altura)

	var proporcion: float = clampf(_bola.z / altura_sombra_max, 0.0, 1.0)
	_sombra.scale = Vector2.ONE * lerpf(1.0, 0.7, proporcion)
	_sombra.modulate.a = lerpf(1.0, 0.6, proporcion)

	var mostrar: bool = _bola.activa and _bola.rebotes == 0 and not _bola.rodando \
			and _bola.tiempo_vuelo >= retraso_marcador
	_marcador.visible = mostrar
	if mostrar:
		var punto: Vector2 = _bola.punto_aterrizaje()
		_marcador.global_position = pista.proyectar(punto)
		if not _marcador_visible_previo:
			_marcador.reset_physics_interpolation()
		var dentro: bool = pista.contiene(punto)
		_marcador.modulate = color_marcador_dentro if dentro else color_marcador_fuera
		var pulso: float = 1.0 + 0.1 * sin(_bola.tiempo_vuelo * 22.0)
		_marcador.scale = Vector2.ONE * pista.escala_en(punto) * pulso
	_marcador_visible_previo = mostrar
