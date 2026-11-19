class_name PanelOpciones
extends Control
## Panel de opciones (volúmenes y pantalla completa). Navegable con mando.
## B (ui_cancel) o el botón Volver lo cierran y guardan.

signal cerrado

@onready var _general: HSlider = $Panel/Caja/FilaGeneral/Deslizador
@onready var _efectos: HSlider = $Panel/Caja/FilaEfectos/Deslizador
@onready var _ambiente: HSlider = $Panel/Caja/FilaAmbiente/Deslizador
@onready var _completa: CheckBox = $Panel/Caja/PantallaCompleta
@onready var _volver: Button = $Panel/Caja/Volver


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_refrescar()
	_general.value_changed.connect(func(v: float) -> void: _cambiar("volumen_general", v))
	_efectos.value_changed.connect(func(v: float) -> void: _cambiar("volumen_efectos", v))
	_ambiente.value_changed.connect(func(v: float) -> void: _cambiar("volumen_ambiente", v))
	_completa.toggled.connect(func(activo: bool) -> void: _cambiar("pantalla_completa", activo))
	_volver.pressed.connect(cerrar)


func abrir() -> void:
	_refrescar()
	visible = true
	_general.grab_focus()


func cerrar() -> void:
	if not visible:
		return
	visible = false
	Opciones.guardar()
	cerrado.emit()


func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento.is_action_pressed(&"ui_cancel"):
		cerrar()
		get_viewport().set_input_as_handled()


func _refrescar() -> void:
	_general.set_value_no_signal(Opciones.volumen_general)
	_efectos.set_value_no_signal(Opciones.volumen_efectos)
	_ambiente.set_value_no_signal(Opciones.volumen_ambiente)
	_completa.set_pressed_no_signal(Opciones.pantalla_completa)


func _cambiar(propiedad: String, valor: Variant) -> void:
	Opciones.set(propiedad, valor)
	Opciones.aplicar()
