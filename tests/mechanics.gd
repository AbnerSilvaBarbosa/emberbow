extends SceneTree
var game: Node
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if value: print("PASS: " + message)
	else:
		failed = true
		push_error("FAIL: " + message)
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.practice(true)
	preload("res://tests/fixture.gd").install(game)
	var p: Node = game.players[1]
	var q: Node = game.players[-1]
	p.position = Vector2(320, 507)
	q.alive = false
	p.invulnerable = 0
	for i in 5:
		p.simulate(1.0 / 60, {})
		await physics_frame
	var start_ammo: int = p.arrows
	p.simulate(1.0 / 60, {"bits": 4, "aim": Vector2.RIGHT})
	check(game.projectiles.is_empty() and p.charge > 0, "Holding shoot enters aiming without consuming ammunition")
	p.simulate(1.0 / 60, {"bits": 0})
	check(game.projectiles.size() == 1 and p.arrows == start_ammo - 1, "Releasing shoot fires exactly one arrow")
	for i in 20: p.simulate(1.0 / 60, {})
	check(game.projectiles.size() == 1, "Idle input does not repeat a released shot")
	p.cooldown = 0
	p.simulate(1.0 / 60, {"bits": 2, "aim": Vector2.RIGHT})
	var recharge: float = p.cooldown
	p.simulate(1.0 / 60, {"bits": 0})
	p.simulate(1.0 / 60, {"bits": 2, "aim": Vector2.LEFT})
	check(p.velocity.x > 0 and p.cooldown < recharge, "Dash cooldown prevents direction-reset spam")
	game.reset_round()
	preload("res://tests/fixture.gd").install(game)
	q.alive = false
	p.position = Vector2(320, 507)
	for i in 5:
		p.simulate(1.0 / 60, {})
		await physics_frame
	p.simulate(1.0 / 60, {"bits": 1})
	await physics_frame
	p.simulate(1.0 / 60, {"bits": 0})
	var short_velocity: float = p.velocity.y
	await physics_frame
	p.simulate(1.0 / 60, {"bits": 1})
	check(p.velocity.y > short_velocity, "Re-pressing jump in air does not grant a second jump")
	check(short_velocity >= -190, "Releasing jump cuts upward speed for a short hop")
	game.reset_round()
	preload("res://tests/fixture.gd").install(game)
	var before: float = game.round_time
	game.toggle_pause()
	game._physics_process(1.0 / 60)
	check(game.menu.visible and game.round_time == before, "Offline pause freezes simulation")
	game.ui.resume()
	check(not game.menu.visible and game.notice.is_empty(), "Resume returns control to the game")
	game.leave("")
	game.ui.change_map(1)
	check(game.map_id == 1 and game.map_select.selected == 1, "Arena selector updates playable map and preview")
	game.ui.select_skin(3)
	game.practice(false)
	check(game.players[1].skin == 3, "Selected archer is used in the match")
	game.leave("")
	game.ui.show_page("online")
	check(game.ui.online.visible and not game.ui.home.visible, "Online connection has a dedicated screen")
	game.queue_free()
	await create_timer(0.2).timeout
	quit(1 if failed else 0)
