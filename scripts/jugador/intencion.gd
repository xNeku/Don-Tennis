class_name Intencion
extends RefCounted
## Órdenes que un controlador (mando, teclado, IA) da a un Personaje. La lógica las ejecuta.
## Los pulsos (golpear, globo...) valen un solo tick: el Personaje los limpia al leerlos.

## Dirección de movimiento (-1..1 en cada eje, y positivo = hacia abajo en pantalla).
var mover: Vector2 = Vector2.ZERO
## Hacia dónde colocar el golpe, en coordenadas de pantalla (como el stick).
var apuntar: Vector2 = Vector2.ZERO
var golpear: bool = false
var globo: bool = false
var dash: bool = false
var plancha: bool = false
var especial: bool = false


func limpiar_pulsos() -> void:
	golpear = false
	globo = false
	dash = false
	plancha = false
	especial = false
