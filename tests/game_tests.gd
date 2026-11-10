## Tests headless de la simulación: movimiento, combate, regla del núcleo, grietas, anillo,
## salto doble, Continue y el Rey del Reinicio. Usan otra partida guardada para no tocar la real.
## godot --headless --path . --script res://tests/game_tests.gd
extends SceneTree

var passed := 0
var failed := 0
var g: Game


func check(cond: bool, name: String) -> void:
	if cond:
		passed += 1
		print("  ok   ", name)
	else:
		failed += 1
		print("  FAIL ", name)


func step(n: int, hold := {}, tap: Array = []) -> void:
	for i in n:
		g.keys.clear()
		g.pressed.clear()
		for k in hold:
			g.keys[k] = hold[k]
		if i == 0:
			for t in tap:
				g.pressed[t] = true
		g.update(1.0 / 60.0)


func fresh() -> void:
	g = Game.new(true)
	step(1, {}, ["confirm"])
	for i in 12:
		step(4, {}, ["confirm"])


## Bot de escalada: empuja hacia una pared y, al deslizarse, salta hacia la otra.
func climb() -> void:
	var dir := -1
	for i in 900:
		var hold := {"jump": true}
		var tap := []
		hold["left" if dir < 0 else "right"] = true
		if g.P.y + g.P.h < 16 * 32:
			hold = {"left": true, "jump": true}  # arriba del pozo: salto hacia la puerta de la Antesala
			tap = ["jump"]
		elif g.P.wall_dir != 0 and g.P.vy >= 0:
			tap = ["jump"]
			dir = -g.P.wall_dir
		step(1, hold, tap)
		if g.room.id != "torre":
			return


func _init() -> void:
	SaveData.path = "user://test_partida.json"
	SaveData.erase()

	print("Inicio y movimiento")
	fresh()
	check(g.state == "play" and g.room.id == "umbral", "tras el título y la intro, Álex está en el Umbral")
	check(g.P.on_ground, "Álex está en el suelo")
	var t := 0
	while g.room.id == "umbral" and t < 900:
		step(1, {"left": true}); t += 1
	step(30)
	check(g.room.id == "inicio", "dejándose caer por el hueco del suelo del Umbral se llega a la Pantalla de Inicio")
	g.P.x = 60 * 32; g.P.y = 15 * 32 - g.P.h; g.P.vy = 0; step(10)
	var y0 := g.P.y
	var top := y0
	step(1, {"jump": true}, ["jump"])
	for i in 50:
		step(1, {"jump": true}); top = minf(top, g.P.y)
	check(y0 - top > 100 and y0 - top < 140, "salto manteniendo: entre 3 y 4,5 casillas (%.0f px)" % (y0 - top))

	print("Combate y núcleos")
	fresh(); g.load_room("inicio", "pasarela"); step(5)
	var c: Game.Ent = g.enemies[0]
	g.P.x = c.x - 30; g.P.y = c.y + c.h - g.P.h; g.P.face = 1
	c.hp = 1
	step(1, {}, ["attack"]); step(2)
	check(c.dead, "un tajo elimina a un rastrero con 1 de vida")
	check(g.P.debug == 1, "acertar suma un punto de depuración")
	var cores := g.enemies.filter(func(e): return e.kind == "core")
	check(cores.size() == 1, "el rastrero deja un núcleo")
	step(60 * 5)
	var back := g.enemies.filter(func(e): return e.kind == "c" and e.revived)
	check(back.size() == 1, "si el núcleo sobrevive 4 s, el rastrero vuelve")
	step(120)
	check(g.meta["frags"] >= 3, "los fragmentos vuelan hacia Álex y se suman")
	g.load_room("inicio", "pasarela"); step(2)
	var sc: Game.Ent = g.mk_enemy("c", 11 * 32 + 16, 15 * 32)
	g.enemies = [sc]
	g.P.x = 2 * 32
	step(30)
	check(sc.dead and g.enemies.filter(func(e): return e.kind == "core").is_empty(), "un rastrero que cae en los pinchos muere y no deja núcleo")

	print("Kira")
	fresh(); g.load_room("inicio", "pasarela"); g.enemies.clear()
	var K: Dictionary = g.props.filter(func(o): return o["type"] == "K")[0]
	g.P.x = K["x"] - 9; g.P.y = K["y"] - g.P.h
	step(3); step(1, {}, ["interact"])
	check(g.state == "dialog" and g.dialog["speaker"] == "Kira Volt", "Kira aparece en la Pantalla de Inicio y habla")
	for i in 12:
		step(4, {}, ["confirm"])
	check(not g.new_kira_talk(1), "tras presentarse, Kira ya no tiene conversación nueva")

	print("Nivel 1-1 de Kira")
	fresh()
	check(g.portal_open(1), "el portal al Nivel 1-1 está abierto aunque no se haya hablado con Kira")
	check(g.props.filter(func(o): return o["type"] == "T").is_empty(), "el portal ya no está junto a Kira")
	g.load_room("cripta", "sotano"); g.enemies.clear(); step(3)
	check(g.tile_at(7, 30) == "w" and g.is_solid("w"), "en la Cripta, el portal está detrás de un muro falso")
	g.P.x = 9 * 32; g.P.y = 32 * 32 - g.P.h; g.P.vy = 0; g.P.face = -1; step(5)
	for i in 4:
		step(1, {}, ["attack"]); step(20)
	check(g.tile_at(7, 30) == "." and g.tile_at(7, 31) == ".", "dos clics por casilla rompen el muro falso")
	var T_: Dictionary = g.props.filter(func(o): return o["type"] == "T")[0]
	g.P.x = T_["x"] - 9; g.P.y = T_["y"] - g.P.h
	step(3); step(1, {}, ["interact"]); step(30)
	check(g.room.id == "kira1" and g.state == "play", "el portal lleva al Nivel 1-1")
	g.enemies.clear()
	check(g.room.g[16][12] == "p", "el puente empieza sin colocar")
	t = 0
	while g.P.x < 21 * 32 and t < 600 and g.state == "play":
		step(1, {"right": true}, ["attack"] if t % 10 == 0 else [])
		t += 1
	check(g.P.x >= 21 * 32 and g.meta["deaths"] == 0, "clicando hacia delante se coloca el puente y se cruza el foso")
	g.P.x = 23 * 32; g.P.y = 16 * 32 - g.P.h; g.P.vy = 0; step(5)
	step(1, {"up": true}, ["attack"]); step(10)
	check(g.room.g[13][23] == "=", "un clic hacia arriba coloca el escalón")
	g.P.x = 41 * 32; g.P.y = 16 * 32 - g.P.h; step(5)
	t = 0
	while g.state == "play" and t < 200:
		step(1, {"right": true}); t += 1
	check(g.meta["kira_frags"] == 1 and g.state == "trans" and g.banner["sub"].ends_with("1 de 6"),
		"la bandera da por terminado el primer trozo, sin Kira, y vuelve a la sala del portal")
	step(30)
	check(g.room.id == "cripta" and not g.portal_open(1), "se vuelve a la cámara secreta de la Cripta y el portal se cierra")

	print("Grietas")
	fresh(); g.load_room("inicio", "pasarela"); g.enemies.clear()
	var F: Dictionary = g.props.filter(func(o): return o["type"] == "F")[0]
	g.P.x = F["x"] - 9; g.P.y = F["y"] - g.P.h
	step(3); step(1, {}, ["interact"])
	check(g.state == "choice" and g.choice["opts"].size() == 3, "la grieta ofrece 3 poderes de su héroe")
	step(25); step(1, {}, ["c2"])
	check(g.state == "play" and g.run["boons"].size() == 1, "elegir con 2 guarda el poder")
	step(1, {}, ["interact"])
	check(g.state == "play", "la grieta ya no ofrece nada más en este intento")

	print("Anillo y Nexo")
	fresh(); g.meta["frags"] = 500
	var M: Dictionary = g.props.filter(func(o): return o["type"] == "M")[0]
	g.P.x = M["x"] - 9; g.P.y = M["y"] - g.P.h
	step(3); step(1, {}, ["interact"])
	check(g.state == "shop", "el anillo abre la tienda")
	step(1, {}, ["confirm"]); step(1, {}, ["down"]); step(1, {}, ["confirm"]); step(1, {}, ["pause"])
	check(g.meta["up"]["corazon"] == 1 and g.meta["up"]["dano"] == 1 and g.meta["frags"] == 445, "comprar un corazón y clic afinado cuesta 55")
	check(g.max_hp() == 6, "el corazón de reserva sube la vida máxima")
	var O: Dictionary = g.props.filter(func(o): return o["type"] == "O")[0]
	g.P.x = O["x"] - 9; g.P.y = O["y"] - g.P.h
	step(3); step(1, {}, ["interact"])
	check(g.state == "dialog" and g.dialog["lines"][0].begins_with("Usuario dev_01"), "Nexo da la bienvenida")

	print("Salto doble")
	fresh(); g.load_room("pantalla", "bloque"); g.enemies.clear(); step(20)
	y0 = g.P.y
	for i in 4:
		step(1, {"jump": true, "right": true}, ["jump"]); step(60, {"jump": true})
	check(g.P.y >= y0 - 1, "sin el orbe no se sube por la Doble Pantalla")
	g.load_room("monedas", "pasarela"); g.enemies.clear()
	var A: Dictionary = g.props.filter(func(o): return o["type"] == "A")[0]
	g.P.x = A["x"] - 9; g.P.y = A["y"] - g.P.h
	step(3)
	check(g.meta["wings"], "tocar el orbe da el salto doble")
	for i in 4:
		step(4, {}, ["confirm"])
	g.load_room("pantalla", "bloque"); g.enemies.clear(); step(20)
	g.P.x = 10 * 32; step(10)
	step(1, {"jump": true}, ["jump"]); step(20, {"jump": true}); step(1, {"jump": true}, ["jump"]); step(40, {"jump": true})
	check(g.P.on_ground and g.P.y < 46 * 32, "con salto doble se sube a la primera plataforma")

	print("Continue")
	fresh(); g.load_room("inicio", "pasarela"); step(5)
	g.run["boons"].append("espadon")
	g.P.hp = 1; g.P.inv = 0; g.P.x = 11 * 32; g.P.y = 14 * 32
	step(30)
	check(g.state == "dead" and g.meta["deaths"] == 1, "caer en los pinchos con 1 corazón es un Continue")
	step(120); step(1, {}, ["confirm"])
	check(g.state == "play" and g.room.id == "umbral" and g.run["boons"].is_empty() and g.P.hp == g.max_hp(), "vuelve al Umbral con toda la vida y sin poderes")

	print("Reino: bloques, arena, fuente y atajos")
	fresh(); g.load_room("inicio", "pasarela"); g.enemies.clear(); step(3)
	check(g.tile_at(20, 13) == "b", "hay un muro agrietado antes de salir de la Pantalla de Inicio")
	g.P.x = 18 * 32; g.P.y = 15 * 32 - g.P.h; g.P.face = 1; step(3)
	for i in 4:
		step(1, {}, ["attack"]); step(20)
	check(g.tile_at(20, 13) == "." and g.tile_at(20, 14) == ".", "dos clics por bloque rompen el muro")
	g.P.x = 28 * 32; g.P.y = 15 * 32 - g.P.h; step(3)
	var f0: int = g.meta["frags"]
	for i in 2:
		step(1, {"up": true}, ["attack"]); step(20)
	step(90)
	check(g.tile_at(28, 12) == "." and g.meta["frags"] >= f0 + 4, "el bloque sorpresa suelta 4 fragmentos")
	g.load_room("arena1", "cruce"); step(3)
	check(g.enemies.is_empty() and not g.arena_active, "la arena empieza vacía y abierta")
	g.P.x = 34 * 32; step(3)
	check(g.arena_active and g.is_solid("d"), "al entrar se cierran las puertas")
	var waves_seen := 0
	t = 0
	while g.arena_active and t < 60 * 30:
		if not g.enemies.is_empty():
			waves_seen = g.arena_wave
			for e in g.enemies:
				e.hp = 1
				g.damage_enemy(e, 5)
		g.P.inv = 1.0
		step(1); t += 1
	check(waves_seen == 3 and g.run["arenas"].has("arena1") and not g.is_solid("d"), "tras tres oleadas la arena se abre")
	g.load_room("arena1", "cruce"); g.P.x = 34 * 32; step(10)
	check(not g.arena_active, "una arena superada no se repite en el mismo intento")
	g.load_room("fuente", "puente"); step(3)
	g.P.hp = 1
	var H_: Dictionary = g.props.filter(func(o): return o["type"] == "h")[0]
	g.P.x = H_["x"] - 9; g.P.y = H_["y"] - g.P.h; step(3); step(1, {}, ["interact"])
	check(g.P.hp == g.max_hp() and g.run["fountains"].has("fuente"), "la fuente cura por completo")
	g.load_room("fuente", "puente"); step(3)
	check(g.props.filter(func(o): return o["type"] == "h").is_empty(), "y no vuelve a salir en el mismo intento")
	g.load_room("pasarela", "inicio"); step(3)
	var gem: Dictionary = g.props.filter(func(o): return o["type"] == "g")[0]
	f0 = g.meta["frags"]
	g.P.x = gem["x"] - 9; g.P.y = gem["y"] - g.P.h; step(3)
	check(g.meta["frags"] == f0 + 8, "los fragmentos escondidos dan 8")
	g.load_room("puente", "chimenea"); g.enemies.clear(); step(3)
	g.P.face = 1
	for i in 4:
		step(1, {}, ["attack"]); step(20)
	check(g.tile_at(4, 13) == "a", "desde la Chimenea el atajo del Puente no se rompe")
	g.P.x = 6 * 32; g.P.y = 15 * 32 - g.P.h; g.P.face = -1; step(3)
	for i in 4:
		step(1, {}, ["attack"]); step(20)
	check(g.tile_at(4, 13) == "." and g.meta["shortcuts"].has("puente"), "desde el Puente se abre el atajo")
	var el := g.mk_enemy("C", 100, 100)
	check(el.elite and el.kind == "c" and el.max_hp > 60, "los élites tienen más vida")
	g.new_run()
	check(g.rooms["inicio"].g[13][20] == "b", "en un intento nuevo los bloques vuelven a estar")
	g.load_room("puente", "fuente"); step(2)
	check(g.tile_at(4, 13) == ".", "pero el atajo sigue abierto para siempre")

	print("Continue Extra")
	fresh(); g.meta["up"]["continue"] = 1; g.new_run(); g.load_room("inicio", "pasarela"); step(5)
	g.P.hp = 1; g.P.inv = 0; g.P.x = 11 * 32; g.P.y = 14 * 32
	t = 0
	while g.run["revive"] > 0 and t < 60:
		step(1); t += 1
	check(g.state == "play" and g.P.hp == 3 and g.run["revive"] == 0, "el Continue Extra salva con media vida")
	check(g.revive_fx > 1.5 and g.hitstop > 0.3, "y se nota: pausa y aviso grande en pantalla")
	step(60 * 3)
	check(g.revive_fx == 0.0, "el aviso desaparece a los pocos segundos")

	print("El Rey del Reinicio")
	fresh(); g.load_room("trono", "arena2"); step(5)
	g.P.hp = 99
	t = 0
	var saw_roar := false
	while g.state != "end" and t < 60 * 90:
		var b := g.boss
		var hold := {}
		if b != null:
			var dx := b.center().x - g.P.center().x
			if absf(dx) > 50:
				hold["right" if dx > 0 else "left"] = true
			if b.state == "roar":
				saw_roar = true
		g.P.inv = 0.5
		step(1, hold, ["attack"] if t % 12 == 0 else [])
		t += 1
		if g.state == "dialog":
			step(1, {}, ["confirm"])
	check(saw_roar, "al entrar, el Rey se presenta y cierra la puerta")
	check(g.state == "end" and g.meta["boss"], "vencer al Rey rompe el bucle (%.0f s)" % (t / 60.0))
	step(150); step(1, {}, ["confirm"])
	check(g.state == "play" and g.room.id == "trono", "tras la pantalla de mundo superado se sigue en el trono")
	check(g.rooms["trono"].g[13][0] == "." and g.rooms["trono"].g[13][63] == ".", "se abren la puerta de entrada y la de la Academia")
	g.P.x = 60 * 32; g.P.y = 15 * 32 - g.P.h
	t = 0
	while g.room.id == "trono" and t < 300:
		step(1, {"right": true}); t += 1
	step(30)
	check(g.room.id == "patio", "por la puerta del trono se llega al Patio de la Academia")
	g.new_run(); g.load_room("trono", "arena2"); step(5)
	check(g.boss != null and g.rooms["trono"].g[13][63] == "#", "en el intento siguiente el Rey vuelve y la puerta está cerrada")

	print("Academia: resonancia y conjurador")
	fresh(); g.load_room("patio", "trono"); g.enemies.clear(); step(5)
	check(g.tile_at(17, 12) == "y" and not g.one_way("y"), "sin resonancia, la plataforma de cristal no se pisa")
	var R: Dictionary = g.props.filter(func(o): return o["type"] == "R")[0]
	g.P.x = R["x"] - 50; g.P.y = R["y"] - g.P.h; g.P.face = 1; step(3)
	step(1, {}, ["attack"]); step(3)
	check(g.P.resonance > 0 and g.one_way("y"), "un clic al cristal hace resonar a Álex y la plataforma se puede pisar")
	g.P.x = 17 * 32; g.P.y = 12 * 32 - g.P.h - 2; g.P.vy = 0; step(10)
	check(g.P.on_ground and g.P.y < 12 * 32, "Álex se sostiene sobre la plataforma de cristal")
	step(60 * 7)
	check(not g.P.on_ground or g.P.y > 12 * 32, "al acabar la resonancia la plataforma desaparece")
	g.load_room("patio", "trono"); step(2)
	var k: Game.Ent = g.mk_enemy("k", 10 * 32, 13 * 32)
	var c2: Game.Ent = g.mk_enemy("c", 20 * 32, 15 * 32)
	c2.hp = 10
	g.enemies = [k, c2]
	g.P.x = 2 * 32; k.cd = 0.0
	step(130)
	check(c2.hp == 25 and c2.shield == 1, "si el conjurador termina el hechizo, cura y da escudo")
	g.P.x = k.x - 40; g.P.y = k.y; g.P.face = 1
	k.charging = true; k.cd = 0.5
	step(1, {}, ["attack"]); step(3)
	check(not k.charging, "un clic interrumpe al conjurador")

	print("Academia: salto en pared")
	fresh(); g.meta["wings"] = true
	g.load_room("torre", "biblioteca"); g.enemies.clear()
	g.P.x = 23 * 32; g.P.y = 45 * 32 - g.P.h; step(5)
	climb()
	check(g.room.id != "antesala", "sin el orbe no se sube la Torre del Examen (%s)" % g.room.id)
	fresh(); g.meta["wings"] = true; g.meta["walljump"] = true
	g.load_room("torre", "biblioteca"); g.enemies.clear()
	g.P.x = 23 * 32; g.P.y = 45 * 32 - g.P.h; step(5)
	step(1, {"jump": true}, ["jump"]); step(6, {"jump": true})
	climb()
	step(30)
	check(g.room.id == "antesala", "con salto en pared se sube la torre hasta la Antesala del Examen")

	print("Aspecto de Álex")
	fresh()
	check(not g.look_offer_pending(), "antes de morir, Nexo no ofrece un aspecto")
	g.meta["deaths"] = 1; g.meta["talk"] = 1
	check(g.look_offer_pending() and g.new_talk(), "tras el primer Continue, Nexo tiene algo que decir")
	g.interact({"type": "O"})
	check(g.state == "dialog" and g.dialog["lines"] == Data.NEXO_LOOK, "Nexo ofrece un aspecto normal")
	for i in 12:
		step(2, {}, ["confirm"])
	check(g.state == "look", "tras la oferta se abre la personalización, y confirmar no la acepta sin llegar a Listo")
	step(1, {}, ["right"])
	check(g.look_edit["look"]["peinado"] == 1, "se cambia de peinado")
	step(1, {}, ["up"])
	check(g.look_edit["sel"] == Data.LOOK_OPTIONS.size(), "la fila de arriba enlaza con Listo")
	step(1, {}, ["confirm"])
	check(g.state == "play" and g.meta["look"]["peinado"] == 1 and not g.look_offer_pending(), "Listo guarda el aspecto y Nexo deja de ofrecerlo")
	check(SaveData._valid_look({"peinado": 99}).is_empty() and SaveData._valid_look(Data.default_look()) == Data.default_look(), "un aspecto guardado inválido se descarta")
	check(SaveData._valid_look({"peinado": 1})["calzado"] == 0 and SaveData._valid_look({}).is_empty(), "una partida anterior conserva su aspecto y las filas nuevas empiezan en la primera opción")

	var skin: Array = Data.LOOK_OPTIONS.filter(func(o): return o["id"] == "piel")[0]["opts"]
	var skin_ok := true
	for i in range(1, skin.size()):
		skin_ok = skin_ok and skin[i - 1]["col"].get_luminance() - skin[i]["col"].get_luminance() > 0.1
	check(skin_ok, "los tonos de piel van de claro a oscuro y se distinguen entre sí")

	print("Mapa")
	fresh()
	g.map_reveal_all = true
	check(g.map_seen_rooms().has("aula") and not g.meta["seen_rooms"].has("aula"),
		"en desarrollo el mapa enseña todo sin marcarlo como descubierto")
	g.map_reveal_all = false
	check(g.meta["seen_rooms"].has(g.room.id), "la sala donde se empieza ya está en el mapa")
	check(not g.meta["seen_rooms"].has("pasarela"), "lo que no se ha pisado no aparece")
	g.load_room("inicio", "pasarela"); step(2)
	check(g.meta["seen_rooms"].has("inicio") and SaveData.load_meta()["seen_rooms"].has("inicio"), "entrar en una sala la descubre y queda guardada")
	step(1, {}, ["map"])
	check(g.state == "map" and g.map_pan.distance_to(Vector2(Data.MAP_ROOMS["inicio"]) + g.P.center() / 32) < 1, "M abre el mapa centrado en Álex")
	var pan0 := g.map_pan
	step(30, {"right": true})
	check(g.map_pan.x > pan0.x + 50, "con las flechas se recorre el mapa")
	step(1, {}, ["map"])
	check(g.state == "play", "M vuelve a cerrarlo")
	var all_rooms := Data.build_rooms()
	var mapped := {}
	var no_overlap := true
	var rects := []
	for id: String in Data.MAP_ROOMS:
		mapped[id] = true
		var r := Rect2i(Data.MAP_ROOMS[id], Vector2i(all_rooms[id].w, all_rooms[id].h))
		no_overlap = no_overlap and not rects.any(func(o): return o.intersects(r))
		rects.append(r)
	check(mapped.size() == all_rooms.keys().filter(func(id): return not id.begins_with("kira")).size(), "todas las salas tienen sitio en el mapa (los niveles de Kira van aparte)")
	check(no_overlap, "las salas del mapa no se pisan")

	print("Mundos 3 a 6: atajos de un sentido y puertas de jefe")
	fresh(); g.load_room("mirador", "azotea"); step(2)
	var up: Dictionary = g.room.exits.filter(func(e): return e["to"] == "escalera")[0]
	check(g.room.g[0][up["a"]] == "#", "desde el Mirador, la Escalera de Incendios está cerrada")
	g.load_room("escalera", "butacas"); step(2)
	g.start_trans("down")
	check(g.meta["shortcuts"].has("escalera>mirador"), "bajar por la Escalera de Incendios abre el atajo")
	g.state = "play"; g.load_room("mirador", "azotea"); step(2)
	check(g.room.g[0][up["a"]] == ".", "y desde entonces el Mirador tiene la puerta abierta")
	g.load_room("aula", "claustro"); step(2)
	var gate: Dictionary = g.room.exits.filter(func(e): return e["to"] == "taquilla")[0]
	check(g.room.g[gate["a"]][0] == "#", "el cine sigue cerrado hasta vencer al Alumno Eterno")

	print("Técnica de Kira")
	fresh(); g.meta["kira_frags"] = 1
	g.load_room("pasillo", "vestibulo"); g.enemies.clear()
	check(g.props.filter(func(o): return o["type"] == "K").is_empty(), "Kira ya no aparece en la Academia")
	check(g.portal_open(2), "con el primer trozo terminado, el portal de su técnica está abierto")
	g.load_room("observatorio", "vestibulo"); g.enemies.clear(); step(3)
	check(g.tile_at(6, 13) == "w" and g.props.any(func(o): return o["type"] == "T"), "su portal está en el Observatorio, detrás de un muro falso")
	g.load_room("kira2", "1"); step(5)
	var dummies := g.enemies.filter(func(e): return e.kind == "dummy")
	check(dummies.size() == 3, "hay tres muñecos de entrenamiento")
	var d1: Game.Ent = dummies[0]
	g.P.x = d1.x - 30; g.P.y = d1.y + d1.h - g.P.h; g.P.face = 1; step(3)
	step(1, {}, ["attack"]); step(20)
	step(1, {"down": true}, ["attack"]); step(20)
	check(d1.idx == 0, "un golpe en el orden equivocado reinicia la combinación")
	for e in dummies:
		e.idx = e.seq.size()
	var d3: Game.Ent = dummies[2]
	d3.idx = d3.seq.size() - 1
	g.P.x = d3.x - 30; g.P.y = d3.y + d3.h - g.P.h; g.P.face = 1; step(20)
	step(1, {}, ["attack"]); step(5)
	check(g.props.any(func(o): return o["type"] == "G"), "con la técnica completa aparece la bandera")
	var G2: Dictionary = g.props.filter(func(o): return o["type"] == "G")[0]
	g.P.x = G2["x"] - 9; g.P.y = G2["y"] - g.P.h; step(3)
	check(g.meta["kira_frags"] == 2 and g.state == "trans", "la bandera da por terminado el segundo trozo")

	print("El Alumno Eterno")
	fresh(); g.load_room("aula", "claustro"); step(5)
	g.P.hp = 99
	t = 0
	var saw_resist := ""
	while g.state != "end" and t < 60 * 120:
		var b := g.boss
		var hold := {}
		if b != null:
			var dx := b.center().x - g.P.center().x
			if absf(dx) > 50:
				hold["right" if dx > 0 else "left"] = true
			if b.resist != "":
				saw_resist = b.resist
		g.P.inv = 0.5
		var tap := []
		if t % 12 == 0:
			tap = ["attack"]
		if t % 40 == 0:
			tap.append("cast")
			g.P.debug = 6
		step(1, hold, tap)
		t += 1
		if g.state == "dialog":
			step(1, {}, ["confirm"])
	check(saw_resist != "", "el Alumno Eterno se vuelve resistente a lo más usado (%s)" % saw_resist)
	check(g.state == "end" and g.meta["boss2"], "vencer al Alumno Eterno supera el mundo 2 (%.0f s)" % (t / 60.0))
	step(150); step(1, {}, ["confirm"])
	check(g.room.id == "umbral", "tras el mundo 2 se vuelve al Umbral")

	SaveData.erase()
	print("\n%d ok, %d fallos" % [passed, failed])
	quit(1 if failed > 0 else 0)
