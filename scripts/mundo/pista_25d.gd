class_name Pista25D
extends Pista
## Opción B: vista 2.5D. El juego sigue siendo 2D, pero la pista se ve en perspectiva:
## lejos (rival) pequeño y estrecho, cerca (jugador) grande y ancho.
##
## La lógica trabaja en un rectángulo fijo (ancho_logico x largo_logico, y=0 lado del rival).
## La perspectiva sale de 4 Marker2D en PANTALLA (`Limites`): las esquinas de la pista.
## Si dibujas tu propia pista a mano, alinea los 4 marcadores con sus esquinas y listo.

## Ancho lógico de la pista (entre líneas laterales).
@export var ancho_logico: float = 180.0
## Largo lógico de la pista (entre líneas de fondo).
@export var largo_logico: float = 220.0
## Posición de la red como fracción del largo (0.5 = centro).
@export_range(0.1, 0.9, 0.01) var posicion_red: float = 0.5

@onready var _lejos_izq: Marker2D = $Limites/EsquinaLejosIzq
@onready var _lejos_der: Marker2D = $Limites/EsquinaLejosDer
@onready var _cerca_izq: Marker2D = $Limites/EsquinaCercaIzq
@onready var _cerca_der: Marker2D = $Limites/EsquinaCercaDer

var _y_lejos: float = 0.0
var _y_cerca: float = 1.0
var _cx_lejos: float = 0.0
var _cx_cerca: float = 0.0
var _s_lejos: float = 1.0
var _s_cerca: float = 2.0
var _u_lejos: float = 1.0
var _u_cerca: float = 0.5
var _h: float = 1.0


func _ready() -> void:
	recalcular()


## Recalcula la perspectiva a partir de las 4 esquinas. Llamar si se mueven en ejecución.
func recalcular() -> void:
	var fl: Vector2 = _lejos_izq.global_position
	var fr: Vector2 = _lejos_der.global_position
	var nl: Vector2 = _cerca_izq.global_position
	var nr: Vector2 = _cerca_der.global_position
	_y_lejos = (fl.y + fr.y) * 0.5
	_y_cerca = (nl.y + nr.y) * 0.5
	_cx_lejos = (fl.x + fr.x) * 0.5
	_cx_cerca = (nl.x + nr.x) * 0.5
	_s_lejos = (fr.x - fl.x) / ancho_logico
	_s_cerca = (nr.x - nl.x) / ancho_logico
	_u_lejos = 1.0 / _s_lejos
	_u_cerca = 1.0 / _s_cerca
	# Perspectiva correcta: la Y de pantalla del suelo es lineal en la escala.
	_h = (_y_cerca - _y_lejos) / (_s_cerca - _s_lejos)


func rect_juego() -> Rect2:
	return Rect2(0.0, 0.0, ancho_logico, largo_logico)


func y_red() -> float:
	return largo_logico * posicion_red


func escala_en(suelo: Vector2) -> float:
	var t: float = suelo.y / largo_logico
	return 1.0 / lerpf(_u_lejos, _u_cerca, t)


func proyectar(suelo: Vector2, z: float = 0.0) -> Vector2:
	var s: float = escala_en(suelo)
	var y_pantalla: float = _y_lejos + _h * (s - _s_lejos)
	var x_pantalla: float = _centro_x(y_pantalla) + (suelo.x - ancho_logico * 0.5) * s
	return Vector2(x_pantalla, y_pantalla - z * factor_altura * s)


func desproyectar(pantalla: Vector2) -> Vector2:
	var s: float = maxf(_s_lejos + (pantalla.y - _y_lejos) / _h, 0.05)
	var t: float = (1.0 / s - _u_lejos) / (_u_cerca - _u_lejos)
	var x: float = ancho_logico * 0.5 + (pantalla.x - _centro_x(pantalla.y)) / s
	return Vector2(x, t * largo_logico)


# X de pantalla de la línea central de la pista a una Y de pantalla dada (recta en pantalla).
func _centro_x(y_pantalla: float) -> float:
	var k: float = (y_pantalla - _y_lejos) / (_y_cerca - _y_lejos)
	return lerpf(_cx_lejos, _cx_cerca, k)
