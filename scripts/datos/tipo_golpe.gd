class_name TipoGolpe
extends Resource
## Tipo de golpe como dato (normal, fuerte, globo...). La física y la IA los tratan igual.

@export var id: StringName = &""
@export var nombre: String = ""
## Segundos que tarda la bola desde el golpe hasta botar. Menos = más rápida.
@export var tiempo_vuelo: float = 0.85
## Altura (z) a la que sale la bola al golpearla.
@export var altura_inicial: float = 20.0
## Potencia 0-1. Gobernará color, sacudida, empuje y knockup (GDD §12).
@export_range(0.0, 1.0, 0.01) var potencia: float = 0.3
