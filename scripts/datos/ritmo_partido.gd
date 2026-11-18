class_name RitmoPartido
extends Resource
## El peloteo se acelera: la bola empieza lenta y gana velocidad con cada golpe seguido.
## Los globos relajan el ritmo. Todo se ajusta en el inspector.

## Multiplicador del tiempo de vuelo al empezar el peloteo (>1 = bola más lenta).
@export var factor_inicial: float = 1.3
## Multiplicador cuando el peloteo está a tope (<1 = bola más rápida).
@export var factor_final: float = 0.8
## Golpes seguidos hasta llegar al factor final.
@export var golpes_hasta_maximo: int = 12
## Cuántos golpes de ritmo se pierden al jugar un globo.
@export var relajacion_globo: int = 3


## 0 = peloteo recién empezado, 1 = a tope.
func progreso(golpes: int) -> float:
	return clampf(float(golpes) / float(maxi(golpes_hasta_maximo, 1)), 0.0, 1.0)


func factor_tiempo(golpes: int) -> float:
	return lerpf(factor_inicial, factor_final, progreso(golpes))
