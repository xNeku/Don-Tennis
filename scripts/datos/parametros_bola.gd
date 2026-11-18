class_name ParametrosBola
extends Resource
## Valores de feel de la física de la bola. Se ajustan en el inspector.

## Gravedad en unidades/s². Más alta = bola más pesada y arcos más cortos.
@export var gravedad: float = 700.0
## Fracción de velocidad vertical que se conserva al botar (0 = no bota, 1 = bota para siempre).
@export_range(0.0, 1.0, 0.01) var restitucion: float = 0.72
## Fracción de velocidad horizontal que se conserva en cada bote.
@export_range(0.0, 1.0, 0.01) var friccion_rebote: float = 0.88
## Radio de contacto de la bola (para golpes y colisiones más adelante).
@export var radio: float = 3.0
## Si tras botar la velocidad vertical queda por debajo de esto, la bola deja de botar y rueda.
@export var velocidad_minima_rebote: float = 30.0
## Frenado de la bola rodando por el suelo (1/s).
@export var friccion_rodar: float = 3.0
## Por debajo de esta velocidad rodando, la bola se da por detenida.
@export var velocidad_parada: float = 6.0
## Tiempo máximo de una bola en juego. Seguro contra bolas eternas.
@export var tiempo_maximo: float = 8.0
## Fracción de velocidad con la que rebota al chocar con la cinta de la red.
@export_range(0.0, 1.0, 0.01) var factor_red: float = 0.15
