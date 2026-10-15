extends SceneTree
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: " + label)
	else:
		failed = true
		push_error(label)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.practice(true)
	game.set_physics_process(false)
	var p = game.players[1]
	var q = game.players[-1]
	game.ui._process(0)
	check(game.ui.health.visible and not game.ui.footer.visible, "Round introduction appears without permanent footer")
	game.next_round = 0
	game.round_time = 1
	game.ui._process(0)
	check(not game.ui.health.visible and not game.ui.countdown.visible, "Combat has no HUD or countdown")
	game.kill(q.pid, p.pid)
	game.hitstop = 0
	game._physics_process(0.016)
	game.ui._process(0)
	check(game.next_round > 3 and p.score - p.round_start_score == 1 and game.ui.health.visible, "Elimination displays round gain before reset")
	var number: int = game.round_number
	game._physics_process(5.5)
	check(game.round_number == number + 1 and p.alive and q.alive and p.round_start_score == p.score, "Next round starts automatically and preserves totals")
	p.score = 2
	game.reset_round()
	game.next_round = 0
	game.round_time = 1
	game.kill(p.pid, p.pid)
	check(p.score - p.round_start_score == -1, "Self elimination appears as a negative round delta")
	game.reset_round()
	p.score = 9
	p.round_start_score = 9
	game.next_round = 0
	game.round_time = 1
	game.kill(q.pid, p.pid)
	game.hitstop = 0
	game._physics_process(0.016)
	check(game.mode == "playing" and game.winner == p.pid and game.next_round > 0, "Winning point still shows the round breakdown")
	game._physics_process(5.5)
	check(game.mode == "finished", "Final results follow the breakdown")
	for index in 6:
		game.build_map(index)
		for slot in 4:
			var point: Vector2 = game.spawn_point(slot)
			var body := Rect2(point - Vector2(9, 13), Vector2(18, 26))
			check(not game.platforms.any(func(r): return r.intersects(body)), "Map %d spawn %d is outside masonry" % [index, slot])
	game.queue_free()
	await create_timer(0.2).timeout
	quit(1 if failed else 0)
