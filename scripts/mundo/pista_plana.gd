class_name PistaPlana
extends Pista
## Opción A: vista plana. Coordenadas lógicas = coordenadas de pantalla.
## La verdad está en los Marker2D de `Limites`: muévelos en el editor y la lógica los sigue.

@onready var _esquina_sup_izq: Marker2D = $Limites/EsquinaSupIzq
@onready var _esquina_inf_der: Marker2D = $Limites/EsquinaInfDer
@onready var _marca_red: Marker2D = $Limites/MarcaRed


func rect_juego() -> Rect2:
	var a: Vector2 = _esquina_sup_izq.global_position
	var b: Vector2 = _esquina_inf_der.global_position
	return Rect2(a, b - a)


func y_red() -> float:
	return _marca_red.global_position.y
