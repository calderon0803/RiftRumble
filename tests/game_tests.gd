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

	print("Kira")
	fresh(); g.load_room("inicio", "1"); g.enemies.clear()
	var K: Dictionary = g.props.filter(func(o): return o["type"] == "K")[0]
	g.P.x = K["x"] - 9; g.P.y = K["y"] - g.P.h
	step(3); step(1, {}, ["interact"])
	check(g.state == "dialog" and g.dialog["speaker"] == "Kira Volt", "Kira aparece en la Pantalla de Inicio y habla")
	for i in 12:
		step(4, {}, ["confirm"])
	check(not g.new_kira_talk(), "tras presentarse, Kira ya no tiene conversación nueva")

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
	check(g.state == "play" and g.room.id == "umbral", "tras el final se vuelve al Umbral")
	check(g.rooms["trono"].g[14][0] == ".", "la puerta del trono queda abierta")

	SaveData.erase()
	print("\n%d ok, %d fallos" % [passed, failed])
	quit(1 if failed > 0 else 0)
