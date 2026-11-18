class_name Golpe
extends RefCounted
## Cálculos de golpe compartidos por jugador e IA.


## Alarga el tiempo de vuelo hasta que la bola pase la red con margen. Un golpe rápido y
## raso se convierte en uno más alto en vez de chocar con la red.
static func tiempo_con_red(g: float, origen: Vector2, z0: float, destino: Vector2, tiempo: float,
		y_red: float, alto_red: float, margen: float) -> float:
	var d_total: float = destino.y - origen.y
	if absf(d_total) < 0.001:
		return tiempo
	var fraccion: float = (y_red - origen.y) / d_total
	if fraccion <= 0.0 or fraccion >= 1.0:
		return tiempo
	var t: float = tiempo
	for i in 20:
		var vz: float = (0.5 * g * t * t - z0) / t
		var t_red: float = fraccion * t
		var z_red: float = z0 + vz * t_red - 0.5 * g * t_red * t_red
		if z_red >= alto_red + margen:
			return t
		t += 0.04
	return t
