extends SceneTree
# Scripted showcase rendered by the real game. Not footage of a human match.
var game: Node
var frame := 0
var finishing := false
func _initialize() -> void: setup.call_deferred()
func setup() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.practice(true)
	game.set_physics_process(false)
	game.spawn(3)
	game.spawn(4)
	game.reset_round()
func _process(dt: float) -> bool:
	if game == null or finishing: return false
	frame += 1
	game.visual_time += dt
	for event in game.particle_events: event.life -= dt
	game.particle_events = game.particle_events.filter(func(e): return e.life > 0)
	if frame < 60:
		game.next_round = (60 - frame) / 30.0
	elif frame < 240 or frame > 360:
		game.next_round = 0
		game.round_time += dt
		for p in game.players.values():
			var direction := 1.0 if p.slot % 2 == 0 else -1.0
			if frame % 120 > 60: direction *= -1
			var bits := 1 if frame % 65 < 20 else 0
			if (frame + p.slot * 9) % 49 < 12: bits |= 4
			if (frame + p.slot * 13) % 91 < 1: bits |= 2
			p.simulate(dt, {"x": direction, "aim": Vector2(direction, -0.25), "bits": bits})
		game.update_arrows(dt)
		game.update_pickups(dt)
		game.stomps()
	elif frame < 300:
		game.round_time = 6
		game.next_round = (300 - frame) / 30.0
		# Explicit demo totals illustrate positive, negative and unchanged scores.
		game.players[1].round_start_score = 2
		game.players[1].score = 3
		game.players[-1].round_start_score = 2
		game.players[-1].score = 1
	elif frame == 300:
		game.build_map(4)
		game.reset_round()
	else: game.next_round = (360 - frame) / 30.0
	game.queue_redraw()
	if frame >= 480:
		finishing = true
		finish.call_deferred()
	return false

func finish() -> void:
	game.queue_free()
	await create_timer(0.2).timeout
	quit()
