## Escena principal: crea el juego y sus vistas, lee los controles y avanza la simulación a 60 Hz.
extends Node2D

var game: Game
var world: WorldView
var ui: UIView


func _ready() -> void:
	Controls.register()
	game = Game.new()
	world = WorldView.new()
	world.game = game
	add_child(world)
	var world_glow := GlowView.new()
	world_glow.source = world
	world.add_child(world_glow)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	ui = UIView.new()
	ui.game = game
	layer.add_child(ui)
	var ui_glow := GlowView.new()
	ui_glow.source = ui
	ui.add_child(ui_glow)


func _physics_process(_delta: float) -> void:
	Controls.read(game.keys, game.pressed)
	game.update(1.0 / 60.0)
	if game.quit_requested:
		game.save()
		get_tree().quit()


func _process(_delta: float) -> void:
	world.queue_redraw()
	ui.queue_redraw()
	for c in [world, ui]:
		for g in c.get_children():
			g.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and game:
		game.save()
