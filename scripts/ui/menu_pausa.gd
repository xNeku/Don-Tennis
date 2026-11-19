class_name MenuPausa
extends CanvasLayer
## Menú de pausa (Esc / Start) y pantalla de fin de partido. Navegable con mando.
## Pausa el árbol; el hitstop de los efectos respeta esta pausa (y al revés).

const ESCENA_MENU: String = "res://scenes/ui/MenuPrincipal.tscn"

## Verdadero mientras el menú está abierto (los efectos no deben quitar la pausa).
static var abierto: bool = false

@onready var _raiz: Control = $Raiz
@onready var _titulo: Label = $Raiz/Caja/Titulo
@onready var _continuar: Button = $Raiz/Caja/Continuar
@onready var _opciones: Button = $Raiz/Caja/Opciones
@onready var _reiniciar: Button = $Raiz/Caja/Reiniciar
@onready var _menu: Button = $Raiz/Caja/MenuPrincipal
@onready var _panel: PanelOpciones = $Raiz/PanelOpciones
@onready var _sonidos: SonidosUI = $SonidosUI

var _es_final: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	abierto = false
	_raiz.visible = false
	_sonidos.conectar(_raiz)
	_continuar.pressed.connect(cerrar)
	_opciones.pressed.connect(_panel.abrir)
	_panel.cerrado.connect(func() -> void:
		_sonidos.tocar_atras()
		_opciones.grab_focus())
	_reiniciar.pressed.connect(_reiniciar_partido)
	_menu.pressed.connect(_ir_al_menu)


func _exit_tree() -> void:
	abierto = false


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"pausa"):
		if _panel.visible:
			_panel.cerrar()
		elif not _raiz.visible:
			abrir()
		elif not _es_final:
			cerrar()
		get_viewport().set_input_as_handled()
	elif _raiz.visible and not _es_final and not _panel.visible and evento.is_action_pressed(&"ui_cancel"):
		_sonidos.tocar_atras()
		cerrar()
		get_viewport().set_input_as_handled()


func abrir() -> void:
	_es_final = false
	_titulo.text = "PAUSA"
	_continuar.visible = true
	_reiniciar.text = "Reiniciar partido"
	_mostrar(_continuar)


## Pantalla de fin de partido: sin "Continuar", con revancha.
func mostrar_final(titulo: String) -> void:
	_es_final = true
	_titulo.text = titulo
	_continuar.visible = false
	_reiniciar.text = "Revancha"
	_mostrar(_reiniciar)


func cerrar() -> void:
	_raiz.visible = false
	abierto = false
	if not EfectosGolpe.hitstop_activo:
		get_tree().paused = false


func _mostrar(primero: Button) -> void:
	abierto = true
	_raiz.visible = true
	get_tree().paused = true
	primero.grab_focus()


func _reiniciar_partido() -> void:
	abierto = false
	get_tree().paused = false
	get_tree().reload_current_scene()


func _ir_al_menu() -> void:
	abierto = false
	get_tree().paused = false
	get_tree().change_scene_to_file(ESCENA_MENU)
