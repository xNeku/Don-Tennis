class_name ParametrosPersonaje
extends Resource
## Valores de feel de un personaje (jugador o rival). Todo se ajusta en el inspector.
## Unidades: distancias en unidades lógicas de pista (180 de ancho x 220 de largo), tiempos en segundos.

@export_group("Movimiento")
@export var velocidad_max: float = 105.0
@export var aceleracion: float = 900.0
@export var deceleracion: float = 1100.0

@export_group("Golpe")
## Tiempo desde pulsar hasta que la raqueta puede golpear.
@export var arranque: float = 0.05
## Ventana en la que la raqueta golpea. El punto dulce está en su mitad.
@export var activa: float = 0.14
@export var recuperacion: float = 0.18
## Distancia máxima (en el suelo) a la que se alcanza la bola.
@export var radio_contacto: float = 18.0
@export var altura_max_contacto: float = 44.0
## Golpe perfecto: error de timing máximo respecto al punto dulce.
@export var ventana_perfecta: float = 0.035
## Fracción de velocidad de movimiento mientras se golpea.
@export_range(0.0, 1.0, 0.05) var velocidad_en_golpe: float = 0.4
## Error máximo de colocación con un golpe de mala calidad.
@export var dispersion_max: float = 22.0
## Hasta dónde se puede colocar a los lados (stick a tope).
@export var alcance_lateral: float = 74.0
## Distancia a la red de una dejada (corta) y de un golpe profundo.
@export var dist_corta: float = 20.0
@export var dist_profunda: float = 96.0
## Un golpe perfecto reduce el tiempo de vuelo a esta fracción.
@export var factor_tiempo_perfecto: float = 0.82
@export var tiempo_minimo: float = 0.34
## Margen mínimo sobre la red que se asegura al golpear.
@export var margen_red: float = 4.0

@export_group("Parry")
## Distancia a la red en la que golpear sin bote cuenta como parry.
@export var zona_parry: float = 38.0
## El parry multiplica la velocidad de la bola por esto.
@export var mult_parry: float = 1.5

@export_group("Rodar (dash)")
@export var rodar_distancia: float = 48.0
@export var rodar_duracion: float = 0.16
@export var rodar_cooldown: float = 0.9

@export_group("Plancha")
@export var plancha_distancia: float = 78.0
@export var plancha_duracion: float = 0.28
@export var plancha_radio: float = 20.0
@export var plancha_altura_max: float = 34.0
@export var tirado_fallo: float = 0.65
@export var tirado_acierto: float = 0.32
@export var plancha_cooldown: float = 0.5

@export_group("Empuje y knockup")
## Potencia de bola recibida a partir de la cual, estando delante, hay knockup.
@export_range(0.0, 1.0, 0.01) var umbral_knockup: float = 0.55
## Distancia a la red que cuenta como "zona delantera".
@export var zona_delantera: float = 55.0
@export var empuje_base: float = 220.0
@export var knockup_distancia: float = 38.0
@export var knockup_duracion: float = 0.8

@export_group("Saque")
@export var saque_altura_inicial: float = 16.0
@export var saque_vz: float = 290.0
@export var saque_altura_max_contacto: float = 95.0
## Saque perfecto: velocidad vertical máxima de la bola al golpearla (cerca del pico).
@export var saque_vz_perfecto: float = 45.0

@export_group("Tipos de golpe")
@export var tipo_normal: TipoGolpe
@export var tipo_globo: TipoGolpe
@export var tipo_saque: TipoGolpe
