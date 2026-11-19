class_name ModoMaquina
extends Resource
## Un modo de la máquina de bolas de la sala de entrenamiento. Otro modo = otro .tres.

enum Destino { ALEATORIO, DERECHA, IZQUIERDA, CENTRO, CORTA, PROFUNDA, ESQUINAS }

@export var nombre: String = ""
## Tipo de golpe de la bola (normal, globo...).
@export var tipo: TipoGolpe
@export var destino: Destino = Destino.ALEATORIO
## Multiplica el tiempo de vuelo del tipo de golpe (menos = bola más rápida).
@export var factor_tiempo: float = 1.0
## Potencia de la bola (color, empuje, knockup). -1 = la del tipo de golpe.
@export_range(-1.0, 1.0, 0.01) var potencia: float = -1.0
## Si es verdadero la bola se acelera con los golpes seguidos, como en un partido (RitmoPartido).
@export var usa_ritmo: bool = false
## Segundos de espera hasta la siguiente bola.
@export var pausa: float = 1.4
