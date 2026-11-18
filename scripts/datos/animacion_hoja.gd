class_name AnimacionHoja
extends Resource
## Una animación: una tira horizontal de frames del mismo tamaño en un PNG.

@export var nombre: StringName = &""
@export var textura: Texture2D
## Número de frames. 0 = automático (ancho de la tira / ancho de frame).
@export var frames: int = 0
@export var fps: float = 8.0
@export var bucle: bool = false
