class_name ParametrosIA
extends Resource
## Personalidad de una IA. Todo es dato: otro rival = otro .tres.

## Segundos que tarda en reaccionar a un golpe del rival.
@export var reaccion: float = 0.22
## Error de posición al ir a la bola (unidades).
@export var error_posicion: float = 4.0
## Error de timing al golpear (desviación típica, en segundos). Más alto = menos golpes perfectos.
@export var error_timing: float = 0.02
## Probabilidad de intentar un parry (volea) cuando puede.
@export_range(0.0, 1.0, 0.01) var agresividad: float = 0.25
@export_range(0.0, 1.0, 0.01) var prob_globo: float = 0.12
@export_range(0.0, 1.0, 0.01) var prob_dejada: float = 0.10
## Probabilidad de no perseguir una bola que va a salir fuera.
@export_range(0.0, 1.0, 0.01) var prob_dejar_pasar: float = 0.85
@export var usa_dash: bool = true
@export var usa_plancha: bool = true
## Cuánto después del bote golpea la bola.
@export var retraso_post_rebote: float = 0.14
## 1 = coloca siempre al hueco; menos = más aleatorio.
@export_range(0.0, 1.0, 0.01) var variedad: float = 0.7
## Distancia a la red a la que espera (menos = más adelantada, más volea y más riesgo de knockup).
@export var distancia_base: float = 92.0
@export var pausa_saque: float = 0.55
@export var error_timing_saque: float = 0.09
