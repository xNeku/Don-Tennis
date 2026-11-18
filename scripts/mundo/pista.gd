class_name Pista
extends Node2D
## Base de las pistas. Define lo común (límites, red) y cómo se proyecta el mundo lógico
## (x, y en el suelo + z de altura) a la pantalla. La lógica (Bola, IA) solo habla en
## coordenadas lógicas y pide a la pista que proyecte; así se puede cambiar el ángulo
## de cámara sin tocar la física. Por defecto la proyección es plana (identidad).

## Altura de la cinta de la red (en unidades z). Una bola por debajo choca con la red.
@export var alto_red: float = 14.0
## Cuánto sube la bola en pantalla por cada unidad de altura z (en la escala local de la bola).
@export var factor_altura: float = 0.6
## Agarre del suelo para los jugadores: más = acelera, frena y gira antes; menos = resbala (tierra, hielo).
@export_range(0.3, 2.0, 0.05) var friccion_jugador: float = 1.0
## Fricción del suelo sobre la bola: más = pierde más velocidad al botar y al rodar.
@export_range(0.3, 2.0, 0.05) var friccion_bola: float = 1.0


## Rectángulo de juego (dentro de las líneas), en coordenadas lógicas.
func rect_juego() -> Rect2:
	return Rect2()


## Coordenada Y lógica de la red.
func y_red() -> float:
	return 0.0


func contiene(punto: Vector2) -> bool:
	return rect_juego().has_point(punto)


## Del mundo lógico (suelo + altura z) a coordenadas globales de pantalla.
func proyectar(suelo: Vector2, z: float = 0.0) -> Vector2:
	return suelo + Vector2(0.0, -z * factor_altura)


## Escala visual en ese punto del suelo (1.0 = tamaño base; cerca de la cámara > lejos).
func escala_en(_suelo: Vector2) -> float:
	return 1.0


## De un punto de pantalla al suelo lógico (z = 0). Inversa de `proyectar`.
func desproyectar(pantalla: Vector2) -> Vector2:
	return pantalla
