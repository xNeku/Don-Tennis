class_name CamaraFeel
extends Camera2D
## Cámara con sacudida. La fuerza va en píxeles enteros (pixel art) y decae sola.

var _fuerza: float = 0.0
var _duracion: float = 0.0
var _t: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 11


## Sacude la cámara. Una sacudida más débil no pisa a una más fuerte en curso.
func sacudir(fuerza: float, duracion: float) -> void:
	var actual: float = _fuerza * (_t / _duracion) if _duracion > 0.0 else 0.0
	if fuerza >= actual:
		_fuerza = fuerza
		_duracion = maxf(duracion, 0.01)
		_t = _duracion


func _process(delta: float) -> void:
	if _t > 0.0:
		_t -= delta
		var a: float = _fuerza * clampf(_t / _duracion, 0.0, 1.0)
		offset = Vector2(roundf(_rng.randf_range(-a, a)), roundf(_rng.randf_range(-a, a) * 0.7))
	else:
		offset = Vector2.ZERO
