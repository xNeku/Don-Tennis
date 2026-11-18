class_name BolaVisual
extends Node2D
## Parte visual de la bola: cuerpo (con altura), sombra y marcador de caída.
## Solo lee el estado de Bola y pide a la Pista que proyecte; no decide nada de la física.
## Pixel art: los sprites NO se escalan. Según la profundidad se elige entre varios tamaños
## dibujados (`texturas_*`, de lejos a cerca) y las posiciones van a píxel entero.
## Visual y Marcador son `top_level`: su posición en pantalla la pone la proyección.

## Segundos tras el golpe antes de que aparezca el marcador (hay que leer algo).
@export var retraso_marcador: float = 0.12
## Altura a la que la sombra pasa a su tamaño más pequeño.
@export var altura_sombra_max: float = 120.0
## Escalas de profundidad a partir de las cuales se pasa al siguiente tamaño de sprite.
@export var umbrales_escala: PackedFloat32Array = PackedFloat32Array([1.4, 1.7])
## Sprites de lejos a cerca. Se sustituyen por los dibujados a mano en la escena.
@export var texturas_bola: Array[Texture2D] = []
@export var texturas_sombra: Array[Texture2D] = []
@export var texturas_marcador: Array[Texture2D] = []
@export var color_marcador_dentro: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var color_marcador_fuera: Color = Color(0.55, 0.57, 0.65, 1.0)

@onready var _bola: Bola = get_parent() as Bola
@onready var _cuerpo: Sprite2D = $Cuerpo
@onready var _sombra: Sprite2D = $Sombra
@onready var _marcador: Sprite2D = $Marcador

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

	var escala: float = pista.escala_en(_bola.position)
	var indice: int = _indice_tamano(escala)
	global_position = pista.proyectar(_bola.position).round()
	_poner_textura(_cuerpo, texturas_bola, indice)
	_cuerpo.position = Vector2(0.0, -roundf(_bola.z * pista.factor_altura * escala))

	# La sombra encoge al subir la bola.
	var indice_sombra: int = maxi(indice - (1 if _bola.z > altura_sombra_max * 0.5 else 0), 0)
	_poner_textura(_sombra, texturas_sombra, indice_sombra)

	var mostrar: bool = _bola.activa and _bola.rebotes == 0 and not _bola.rodando \
			and _bola.tiempo_vuelo >= retraso_marcador
	_marcador.visible = mostrar
	if mostrar:
		var punto: Vector2 = _bola.punto_aterrizaje()
		_marcador.global_position = pista.proyectar(punto).round()
		if not _marcador_visible_previo:
			_marcador.reset_physics_interpolation()
		_poner_textura(_marcador, texturas_marcador, _indice_tamano(pista.escala_en(punto)))
		var dentro: bool = pista.contiene(punto)
		_marcador.modulate = color_marcador_dentro if dentro else color_marcador_fuera
		# Parpadeo por alfa (escalar un sprite de pixel art lo deforma).
		_marcador.modulate.a = 0.75 + 0.25 * signf(sin(_bola.tiempo_vuelo * 22.0))
	_marcador_visible_previo = mostrar


func _indice_tamano(escala: float) -> int:
	var indice: int = 0
	for umbral: float in umbrales_escala:
		if escala >= umbral:
			indice += 1
	return indice


func _poner_textura(sprite: Sprite2D, texturas: Array[Texture2D], indice: int) -> void:
	if texturas.is_empty():
		return
	var textura: Texture2D = texturas[mini(indice, texturas.size() - 1)]
	if sprite.texture != textura:
		sprite.texture = textura
