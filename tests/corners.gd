extends SceneTree
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, text: String) -> void:
	if ok: print("PASS: " + text)
	else:
		failed = true
		push_error(text)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.practice(true)
	game.set_physics_process(false)
	preload("res://tests/fixture.gd").install(game)
	await physics_frame
	var p = game.players[1]
	p.position = Vector2(342, 406)
	p.velocity = Vector2(0, -300)
	p.simulate(1.0 / 60, {"bits": 1})
	check(p.position.x < 342 and p.velocity.y < 0, "A grazing jump clears the corner without losing upward speed")
	p.position = Vector2(480, 406)
	p.velocity = Vector2(0, -300)
	p.simulate(1.0 / 60, {"bits": 1})
	check(p.position.x == 480 and p.position.y >= 405, "A solid ceiling still blocks the jump")
	p.position = Vector2(339, 308)
	p.velocity = Vector2(570, 0)
	p.dash = 0.15
	p.simulate(1.0 / 60, {})
	check(p.position.x > 340 and p.position.y < 308, "Dash clears a slightly overlapping ledge")
	p.position = Vector2(339, 350)
	p.velocity = Vector2(570, 0)
	p.dash = 0.15
	p.simulate(1.0 / 60, {})
	check(p.position.x < 342, "Dash cannot correct through a full wall")
	p.position = Vector2(320, 400)
	p.velocity = Vector2(0, 100)
	p.dash = 0
	p.jump_buffer = 0
	p.simulate(1.0 / 60, {})
	check(absf(p.position.x - 320) < 0.1 and p.position.y > 400, "Falling does not snap sideways")
	game.queue_free()
	await create_timer(0.2).timeout
	quit(1 if failed else 0)
