extends Control
## Menú principal: navegable con mando (cruceta o stick, A aceptar, B atrás).

const ESCENA_PARTIDO: String = "res://scenes/Partido.tscn"
const ESCENA_ENTRENAMIENTO: String = "res://scenes/Entrenamiento.tscn"

@onready var _jugar: Button = $Botones/Jugar
@onready var _entrenar: Button = $Botones/Entrenamiento
@onready var _opciones: Button = $Botones/Opciones
@onready var _salir: Button = $Botones/Salir
@onready var _panel: PanelOpciones = $PanelOpciones
@onready var _sonidos: SonidosUI = $SonidosUI


func _ready() -> void:
	_jugar.grab_focus()
	_sonidos.conectar(self)
	_jugar.pressed.connect(_ir.bind(ESCENA_PARTIDO))
	_entrenar.disabled = not ResourceLoader.exists(ESCENA_ENTRENAMIENTO)
	_entrenar.pressed.connect(_ir.bind(ESCENA_ENTRENAMIENTO))
	_opciones.pressed.connect(_panel.abrir)
	_panel.cerrado.connect(func() -> void:
		_sonidos.tocar_atras()
		_opciones.grab_focus())
	_salir.pressed.connect(get_tree().quit)


func _ir(escena: String) -> void:
	get_tree().change_scene_to_file(escena)
