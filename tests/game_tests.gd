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
	for i in 420:
		var hold := {"jump": true}
		var tap := []
		hold["left" if dir < 0 else "right"] = true
		if g.P.wall_dir != 0 and g.P.vy >= 0:
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
		step(1, {"right": true}); t += 1
	step(30)
	check(g.room.id == "inicio", "andando a la derecha se llega a la Pantalla de Inicio")
	var y0 := g.P.y
	var top := y0
	step(1, {"jump": true}, ["jump"])
	for i in 50:
		step(1, {"jump": true}); top = minf(top, g.P.y)
	check(y0 - top > 100 and y0 - top < 140, "salto manteniendo: entre 3 y 4,5 casillas (%.0f px)" % (y0 - top))

	print("Combate y núcleos")
	fresh(); g.load_room("inicio", "1"); step(5)
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
	g.load_room("inicio", "1"); step(2)
	var sc: Game.Ent = g.mk_enemy("c", 19 * 32 + 16, 15 * 32)
	g.enemies = [sc]
	g.P.x = 2 * 32
	step(30)
	check(sc.dead and g.enemies.filter(func(e): return e.kind == "core").is_empty(), "un rastrero que cae en los pinchos muere y no deja núcleo")

	print("Kira")
	fresh(); g.load_room("inicio", "1"); g.enemies.clear()
	var K: Dictionary = g.props.filter(func(o): return o["type"] == "K")[0]
	g.P.x = K["x"] - 9; g.P.y = K["y"] - g.P.h
	step(3); step(1, {}, ["interact"])
	check(g.state == "dialog" and g.dialog["speaker"] == "Kira Volt", "Kira aparece en la Pantalla de Inicio y habla")
	for i in 12:
		step(4, {}, ["confirm"])
	check(not g.new_kira_talk(1), "tras presentarse, Kira ya no tiene conversación nueva")

	print("Nivel 1-1 de Kira")
	check(g.portal_open(1), "tras hablar con Kira se abre su nivel")
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
	check(g.meta["kira_frags"] == 1 and g.state == "dialog", "la bandera enciende la primera muesca y Kira habla")
	for i in 12:
		step(4, {}, ["confirm"])
	step(30)
	check(g.room.id == "inicio" and not g.portal_open(1), "se vuelve a la Pantalla de Inicio y el portal se cierra")

	print("Grietas")
	fresh(); g.load_room("inicio", "1"); g.enemies.clear()
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
	fresh(); g.load_room("pantalla", "1"); g.enemies.clear(); step(20)
	y0 = g.P.y
	for i in 4:
		step(1, {"jump": true, "right": true}, ["jump"]); step(60, {"jump": true})
	check(g.P.y >= y0 - 1, "sin el orbe no se sube por la Doble Pantalla")
	g.load_room("monedas", "1"); g.enemies.clear()
	var A: Dictionary = g.props.filter(func(o): return o["type"] == "A")[0]
	g.P.x = A["x"] - 9; g.P.y = A["y"] - g.P.h
	step(3)
	check(g.meta["wings"], "tocar el orbe da el salto doble")
	for i in 4:
		step(4, {}, ["confirm"])
	g.load_room("pantalla", "1"); g.enemies.clear(); step(20)
	g.P.x = 5 * 32; step(10)
	step(1, {"jump": true}, ["jump"]); step(20, {"jump": true}); step(1, {"jump": true}, ["jump"]); step(40, {"jump": true})
	check(g.P.on_ground and g.P.y < 33 * 32, "con salto doble se sube a la primera plataforma")

	print("Continue")
	fresh(); g.load_room("inicio", "1"); step(5)
	g.run["boons"].append("espadon")
	g.P.hp = 1; g.P.inv = 0; g.P.x = 19 * 32; g.P.y = 14 * 32
	step(30)
	check(g.state == "dead" and g.meta["deaths"] == 1, "caer en los pinchos con 1 corazón es un Continue")
	step(120); step(1, {}, ["confirm"])
	check(g.state == "play" and g.room.id == "umbral" and g.run["boons"].is_empty() and g.P.hp == g.max_hp(), "vuelve al Umbral con toda la vida y sin poderes")

	print("Continue Extra")
	fresh(); g.meta["up"]["continue"] = 1; g.new_run(); g.load_room("inicio", "1"); step(5)
	g.P.hp = 1; g.P.inv = 0; g.P.x = 19 * 32; g.P.y = 14 * 32
	t = 0
	while g.run["revive"] > 0 and t < 60:
		step(1); t += 1
	check(g.state == "play" and g.P.hp == 3 and g.run["revive"] == 0, "el Continue Extra salva con media vida")
	check(g.revive_fx > 1.5 and g.hitstop > 0.3, "y se nota: pausa y aviso grande en pantalla")
	step(60 * 3)
	check(g.revive_fx == 0.0, "el aviso desaparece a los pocos segundos")

	print("El Rey del Reinicio")
	fresh(); g.load_room("trono", "1"); step(5)
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
	check(g.rooms["trono"].g[14][0] == "." and g.rooms["trono"].g[14][39] == ".", "se abren la puerta de entrada y la de la Academia")
	g.P.x = 37 * 32; g.P.y = 16 * 32 - g.P.h
	t = 0
	while g.room.id == "trono" and t < 300:
		step(1, {"right": true}); t += 1
	step(30)
	check(g.room.id == "patio", "por la puerta del trono se llega al Patio de la Academia")
	g.new_run(); g.load_room("trono", "1"); step(5)
	check(g.boss != null and g.rooms["trono"].g[14][39] == "#", "en el intento siguiente el Rey vuelve y la puerta está cerrada")

	print("Academia: resonancia y conjurador")
	fresh(); g.load_room("patio", "1"); g.enemies.clear(); step(5)
	check(g.tile_at(17, 12) == "y" and not g.one_way("y"), "sin resonancia, la plataforma de cristal no se pisa")
	var R: Dictionary = g.props.filter(func(o): return o["type"] == "R")[0]
	g.P.x = R["x"] - 50; g.P.y = R["y"] - g.P.h; g.P.face = 1; step(3)
	step(1, {}, ["attack"]); step(3)
	check(g.P.resonance > 0 and g.one_way("y"), "un clic al cristal hace resonar a Álex y la plataforma se puede pisar")
	g.P.x = 17 * 32; g.P.y = 12 * 32 - g.P.h - 2; g.P.vy = 0; step(10)
	check(g.P.on_ground and g.P.y < 12 * 32, "Álex se sostiene sobre la plataforma de cristal")
	step(60 * 7)
	check(not g.P.on_ground or g.P.y > 12 * 32, "al acabar la resonancia la plataforma desaparece")
	g.load_room("patio", "1"); step(2)
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
	g.load_room("torre", "1"); g.enemies.clear()
	g.P.x = 6 * 32; g.P.y = 32 * 32 - g.P.h; step(5)
	climb()
	check(g.room.id != "aula", "sin el orbe no se sube la Torre del Examen (%s)" % g.room.id)
	fresh(); g.meta["wings"] = true; g.meta["walljump"] = true
	g.load_room("torre", "1"); g.enemies.clear()
	g.P.x = 6 * 32; g.P.y = 32 * 32 - g.P.h; step(5)
	step(1, {"jump": true}, ["jump"]); step(6, {"jump": true})
	climb()
	step(30)
	check(g.room.id == "aula", "con salto en pared se sube la torre hasta el Aula Magna")

	print("Técnica de Kira")
	fresh(); g.meta["kira_talk"] = 1; g.meta["kira_frags"] = 1
	g.load_room("pasillo", "1"); g.enemies.clear()
	var K2: Dictionary = g.props.filter(func(o): return o["type"] == "K")[0]
	g.P.x = K2["x"] - 9; g.P.y = K2["y"] - g.P.h
	step(3); step(1, {}, ["interact"])
	check(g.state == "dialog" and g.dialog["lines"][0].begins_with("Álex. Esta es tu Academia"), "Kira aparece en la Academia")
	for i in 12:
		step(4, {}, ["confirm"])
	check(g.portal_open(2), "se abre la sala de su técnica")
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
	check(g.meta["kira_frags"] == 2 and g.state == "dialog", "la bandera enciende la segunda muesca")

	print("El Alumno Eterno")
	fresh(); g.load_room("aula", "1"); step(5)
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
