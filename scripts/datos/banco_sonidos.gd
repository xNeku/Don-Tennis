class_name BancoSonidos
extends Resource
## Todos los sonidos de un escenario, por id.

@export var eventos: Array[SonidoEvento] = []

var _indice: Dictionary = {}


func buscar(id: StringName) -> SonidoEvento:
	if _indice.is_empty():
		for e: SonidoEvento in eventos:
			_indice[e.id] = e
	return _indice.get(id, null)
