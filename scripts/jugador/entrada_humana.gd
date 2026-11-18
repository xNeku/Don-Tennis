class_name EntradaHumana
extends Node
## Traduce el Input Map (mando y teclado) en órdenes para un Personaje.

@export var activo: bool = true

var personaje: Personaje


func configurar(p: Personaje) -> void:
	personaje = p
	process_physics_priority = -10


func _physics_process(_delta: float) -> void:
	if not activo or personaje == null:
		return
	var i: Intencion = personaje.intencion
	var v: Vector2 = Input.get_vector(&"mover_izq", &"mover_der", &"mover_arriba", &"mover_abajo")
	i.mover = v
	i.apuntar = v
	if Input.is_action_just_pressed(&"golpear"):
		i.golpear = true
	if Input.is_action_just_pressed(&"globo"):
		i.globo = true
	if Input.is_action_just_pressed(&"dash"):
		i.dash = true
	if Input.is_action_just_pressed(&"plancha"):
		i.plancha = true
	if Input.is_action_just_pressed(&"especial"):
		i.especial = true
