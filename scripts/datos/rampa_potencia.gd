class_name RampaPotencia
extends Resource
## Graduación de color según la potencia de la bola (0-1). Rampa de rojos del GDD §12.

## Un color por nivel (de menos a más potente).
@export var colores: PackedColorArray = PackedColorArray([
	Color(1, 1, 1), Color(1, 0.8, 0.45), Color(1, 0.55, 0.38), Color(0.95, 0.28, 0.28), Color(0.72, 0.1, 0.18)])
## Potencia mínima de cada nivel.
@export var umbrales: PackedFloat32Array = PackedFloat32Array([0.0, 0.35, 0.55, 0.75, 0.84])


func nivel(potencia: float) -> int:
	var n: int = 0
	for i in umbrales.size():
		if potencia >= umbrales[i]:
			n = i
	return mini(n, colores.size() - 1)


func color_para(potencia: float) -> Color:
	return colores[nivel(potencia)]
