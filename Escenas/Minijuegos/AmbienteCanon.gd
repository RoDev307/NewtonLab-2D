extends Node2D

var tiempo: float = 0
var chispas: Array[Dictionary] = []
var rastro: Array[Vector2] = []
var reloj: float = 0

func destello(posicion: Vector2) -> void:
	for i in range(14):
		var angulo := TAU * i / 14.0
		chispas.append({"pos": posicion, "vel": Vector2.from_angle(angulo) * (75 + i * 8), "vida": 0.6})

func _process(delta: float) -> void:
	tiempo += delta
	reloj += delta
	var proyectil = get_parent().get_node("Escenario/Proyectil")
	if proyectil.lanzado and reloj > 0.04:
		reloj = 0
		if proyectil.position.y < 575:
			rastro.append(proyectil.position)
		if rastro.size() > 28:
			rastro.pop_front()
	for i in range(chispas.size() - 1, -1, -1):
		chispas[i]["vida"] -= delta
		chispas[i]["pos"] += chispas[i]["vel"] * delta
		chispas[i]["vel"].y += 220 * delta
		if chispas[i]["vida"] <= 0:
			chispas.remove_at(i)
	queue_redraw()

func _nube(posicion: Vector2, escala: float) -> void:
	for parte in [Vector3(-36, 0, 24), Vector3(-9, -12, 32), Vector3(24, -3, 27), Vector3(48, 7, 18)]:
		draw_circle(posicion + Vector2(parte.x, parte.y) * escala, parte.z * escala, Color("ffffffb0"))

func _draw() -> void:
	# Paisaje dibujado: sin recursos externos ni cambios en las colisiones.
	draw_rect(Rect2(-2000, -2000, 5280, 4000), Color("a9dfe7"))
	for i in range(36):
		var tono := Color("86cadc").lerp(Color("e2f2db"), i / 35.0)
		draw_rect(Rect2(0, i * 17, 1280, 18), tono)
	draw_circle(Vector2(1090, 330), 65, Color("fff0b04a"))
	draw_circle(Vector2(1090, 330), 43, Color("fff0b0"))
	_nube(Vector2(280 + sin(tiempo * 0.08) * 20, 300), 1.1)
	_nube(Vector2(850 + sin(tiempo * 0.06) * 25, 290), 0.85)
	_nube(Vector2(1190 + sin(tiempo * 0.1) * 10, 230), 0.65)
	draw_colored_polygon(PackedVector2Array([Vector2(0,540),Vector2(0,460),Vector2(170,340),Vector2(340,460),Vector2(540,315),Vector2(770,500),Vector2(950,360),Vector2(1280,480),Vector2(1280,580)]), Color("83b9b5"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,580),Vector2(0,515),Vector2(210,445),Vector2(390,500),Vector2(710,405),Vector2(990,495),Vector2(1160,445),Vector2(1280,490),Vector2(1280,580)]), Color("609f91"))
	for i in range(12):
		var x := float(i * 116 + 36)
		var y := 535.0 + sin(i * 1.8) * 15
		draw_line(Vector2(x, y), Vector2(x, 580), Color("688b64"), 7)
		draw_circle(Vector2(x,y - 8), 22, Color("478570"))
		draw_circle(Vector2(x - 14,y + 4), 19, Color("51937a"))
	# Tierra, césped y plataforma del cañón.
	draw_rect(Rect2(-2000, 580, 5280, 2000), Color("8d6349"))
	draw_rect(Rect2(-2000, 580, 5280, 15), Color("8dc974"))
	draw_rect(Rect2(-2000, 595, 5280, 7), Color("56835c"))
	for i in range(64):
		var x := float(i * 21)
		draw_line(Vector2(x, 583), Vector2(x + 4, 574 - sin(i) * 4), Color("8dc974"), 3)
	for i in range(55):
		var punto := Vector2(float((i * 97) % 1280), 620.0 + float((i * 31) % 90))
		draw_circle(punto, 2 + i % 3, Color("b2855d"))
	draw_style_box(_plataforma(), Rect2(60, 547, 180, 33))
	# Banderín de objetivos.
	draw_line(Vector2(664, 580), Vector2(664, 381), Color("e2e3c9"), 5)
	var ondeo := sin(tiempo * 3) * 5
	draw_colored_polygon(PackedVector2Array([Vector2(667,382),Vector2(733,389 + ondeo),Vector2(718,407 + ondeo),Vector2(667,409)]), Color("f18c68"))
	# Estación educativa y marcas de distancia decorativas.
	var fuente := ThemeDB.fallback_font
	draw_line(Vector2(903,580),Vector2(903,469),Color("567779"),7)
	draw_line(Vector2(1087,580),Vector2(1087,469),Color("567779"),7)
	var cartel := StyleBoxFlat.new()
	cartel.bg_color = Color("f3edd5")
	cartel.border_color = Color("527e83")
	cartel.set_border_width_all(4)
	cartel.set_corner_radius_all(10)
	draw_style_box(cartel,Rect2(860,432,270,100))
	draw_string(fuente,Vector2(881,458),"EXPERIMENTA",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("38616a"))
	draw_string(fuente,Vector2(881,488),"Masa fija: ↑ fuerza → ↑ a",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("224c58"))
	draw_string(fuente,Vector2(881,512),"Fuerza fija: ↑ masa → ↓ a",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("224c58"))
	for i in range(9):
		var x := 280.0 + i * 100
		draw_line(Vector2(x,603),Vector2(x,611),Color("e7d5ae"),2)
	# Flores pequeñas junto al área de pruebas.
	for x in [40, 290, 760, 1200]:
		draw_line(Vector2(x,580),Vector2(x,564),Color("386c58"),2)
		for i in range(5):
			draw_circle(Vector2(x,562)+Vector2.from_angle(i*TAU/5)*4,3,Color("fff0b0"))
		draw_circle(Vector2(x,562),2,Color("dfaa4d"))
	for i in range(rastro.size()):
		draw_circle(rastro[i], 2 + 3.0 * i / maxf(rastro.size(), 1), Color(1,0.88,0.55,0.08 + 0.3 * i / maxf(rastro.size(),1)))
	for chispa in chispas:
		draw_circle(chispa["pos"], 3, Color(1,0.8,0.35,chispa["vida"] / 0.6))

func _plataforma() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("456775")
	estilo.set_corner_radius_all(8)
	return estilo
