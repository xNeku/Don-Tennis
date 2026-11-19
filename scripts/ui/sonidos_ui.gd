class_name SonidosUI
extends Node
## Sonidos de interfaz: moverse por el menú, aceptar y volver. Funciona también con el juego en pausa.

@export var mover: AudioStream
@export var aceptar: AudioStream
@export var atras: AudioStream

var _voces: Array[AudioStreamPlayer] = []
var _t_mover: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 3:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = &"UI"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_voces.append(p)


## Conecta el sonido de mover (al enfocar) y de aceptar (al pulsar) a todos los botones y deslizadores de `raiz`.
func conectar(raiz: Node) -> void:
	for n: Node in raiz.find_children("*", "BaseButton", true, false):
		(n as BaseButton).focus_entered.connect(tocar_mover)
		(n as BaseButton).pressed.connect(tocar.bind(aceptar))
	for n: Node in raiz.find_children("*", "Slider", true, false):
		(n as Slider).focus_entered.connect(tocar_mover)
		(n as Slider).value_changed.connect(func(_v: float) -> void: tocar_mover())


func tocar_mover() -> void:
	var ahora: float = Time.get_ticks_msec() / 1000.0
	if ahora - _t_mover < 0.06:
		return
	_t_mover = ahora
	tocar(mover)


func tocar_atras() -> void:
	tocar(atras)


func tocar(stream: AudioStream) -> void:
	if stream == null:
		return
	for v: AudioStreamPlayer in _voces:
		if not v.playing:
			v.stream = stream
			v.play()
			return
	_voces[0].stream = stream
	_voces[0].play()
