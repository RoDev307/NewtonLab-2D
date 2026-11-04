extends Node2D
# Solo dibujo: no modifica cuerpos, formas ni parámetros físicos.
var angulo: float = rad_to_deg(atan(0.5))
var tipo: String = "caja"

func _draw() -> void:
	if tipo == "canon":
		_canon()
	elif tipo == "bola":
		draw_circle(Vector2.ZERO, 22, Color("c95728"))
		draw_circle(Vector2(-2,-3), 19, Color("f78b3d"))
		draw_circle(Vector2(-7,-9), 7, Color("ffd087"))
		draw_arc(Vector2.ZERO, 19, 0.2, 1.5, 20, Color("dc6a29"), 3, true)
	else:
		_caja()

func _caja() -> void:
	draw_rect(Rect2(-22,-22,44,44), Color("774c33"))
	draw_rect(Rect2(-19,-19,38,38), Color("c68a4d"))
	for y in [-12.0,0.0,12.0]:
		draw_line(Vector2(-17,y), Vector2(17,y), Color("a9703d"), 1)
		draw_line(Vector2(-15,y+3), Vector2(8,y+3), Color("d8a465"), 1)
	draw_line(Vector2(-16,-16),Vector2(16,16),Color("784c2e"),6,true)
	draw_line(Vector2(-16,16),Vector2(16,-16),Color("eac184"),5,true)
	draw_rect(Rect2(-21,-21,42,5),Color("f1c58a"))
	draw_rect(Rect2(-21,-16,5,37),Color("e1ad6d"))
	draw_rect(Rect2(16,-16,5,37),Color("ac713c"))
	draw_rect(Rect2(-16,16,32,5),Color("9a6338"))
	for x in [-18,18]:
		for y in [-18,18]:
			draw_circle(Vector2(x,y),1.6,Color("664938"))

func _canon() -> void:
	# El tubo conserva su dirección y la boca del diseño original.
	draw_set_transform(Vector2.ZERO, -(deg_to_rad(angulo) - atan(0.5)))
	var tubo := PackedVector2Array([Vector2(-15,-15),Vector2(85,-65),Vector2(100,-35),Vector2(0,15)])
	draw_colored_polygon(tubo,Color("276887"))
	draw_colored_polygon(PackedVector2Array([Vector2(-14,-15),Vector2(85,-65),Vector2(90,-54),Vector2(-9,-5)]),Color("71bfd0"))
	draw_colored_polygon(PackedVector2Array([Vector2(-2,6),Vector2(97,-43),Vector2(100,-35),Vector2(0,15)]),Color("17445f"))
	draw_line(Vector2(78,-62),Vector2(94,-31),Color("b5dee0"),8,true)
	draw_line(Vector2(85,-65),Vector2(100,-35),Color("143c53"),5,true)
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(0,0),21,Color("1f4b66"))
	draw_rect(Rect2(-38,7,76,20),Color("214659"))
	draw_rect(Rect2(-33,7,66,5),Color("588a98"))
	for x in [-26,26]:
		draw_circle(Vector2(x,17),3,Color("a8cad0"))
	draw_circle(Vector2(0,27),26,Color("15384c"))
	draw_circle(Vector2(0,25),22,Color("e2af51"))
	draw_circle(Vector2(0,25),16,Color("f4cc75"))
	for i in range(8):
		var dir := Vector2.from_angle(i * TAU / 8)
		draw_line(Vector2(0,25)+dir*7,Vector2(0,25)+dir*17,Color("b88038"),3,true)
	draw_circle(Vector2(0,25),9,Color("23546b"))
	draw_circle(Vector2(-2,22),3,Color("82b8c0"))
