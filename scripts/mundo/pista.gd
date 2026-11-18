class_name Pista
extends Node2D
## Geometría lógica de la pista. La verdad está en los Marker2D de `Limites`:
## muévelos en el editor y la lógica los sigue. Las líneas y el decorado son solo visuales.

## Altura de la cinta de la red (en unidades z). Una bola por debajo choca con la red.
@export var alto_red: float = 14.0

@onready var _esquina_sup_izq: Marker2D = $Limites/EsquinaSupIzq
@onready var _esquina_inf_der: Marker2D = $Limites/EsquinaInfDer
@onready var _marca_red: Marker2D = $Limites/MarcaRed


## Rectángulo de juego (dentro de las líneas), en coordenadas globales.
func rect_juego() -> Rect2:
	var a: Vector2 = _esquina_sup_izq.global_position
	var b: Vector2 = _esquina_inf_der.global_position
	return Rect2(a, b - a)


## Coordenada Y de la red.
func y_red() -> float:
	return _marca_red.global_position.y


func contiene(punto: Vector2) -> bool:
	return rect_juego().has_point(punto)
