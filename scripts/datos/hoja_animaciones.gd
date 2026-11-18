class_name HojaAnimaciones
extends Resource
## Todas las animaciones de un personaje. Para cambiar el arte: cambia la textura de cada
## animación (tira horizontal de frames del mismo tamaño). Los pies van anclados abajo en el centro.

@export var tamano_frame: Vector2i = Vector2i(48, 48)
@export var animaciones: Array[AnimacionHoja] = []


func construir_frames() -> SpriteFrames:
	var sf: SpriteFrames = SpriteFrames.new()
	sf.remove_animation(&"default")
	for a: AnimacionHoja in animaciones:
		sf.add_animation(a.nombre)
		sf.set_animation_speed(a.nombre, a.fps)
		sf.set_animation_loop(a.nombre, a.bucle)
		var n: int = a.frames if a.frames > 0 else a.textura.get_width() / tamano_frame.x
		for i in n:
			var region: AtlasTexture = AtlasTexture.new()
			region.atlas = a.textura
			region.region = Rect2(i * tamano_frame.x, 0, tamano_frame.x, tamano_frame.y)
			sf.add_frame(a.nombre, region)
	return sf
