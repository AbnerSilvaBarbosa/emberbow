extends SceneTree
var failed := false
var game: Node
const DT := 1.0 / 60
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: " + label)
	else:
		failed = true
		push_error(label)
func reset() -> void:
	game.reset_round()
	preload("res://tests/fixture.gd").install(game)
	for p in game.players.values(): p.invulnerable = 0
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.practice(true)
	game.set_physics_process(false)
	var p = game.players[1]
	var q = game.players[-1]
	reset()
	p.position = Vector2(180, 507)
	q.position = Vector2(230, 507)
	for i in 35:
		p.simulate(DT, {"x": 1})
		q.simulate(DT, {"x": -1})
		await physics_frame
	check(q.position.x - p.position.x >= 17.9, "Opposing players cannot walk through each other")
	p.cooldown = 0
	for i in 20:
		p.simulate(DT, {"bits": 2, "aim": Vector2.RIGHT})
		await physics_frame
	check(q.position.x - p.position.x >= 17.9, "Dash cannot pass through another player")
	reset()
	p.position = Vector2(320, 440)
	q.position = Vector2(320, 507)
	p.velocity.y = 220
	for i in 20:
		p.simulate(DT, {})
		await physics_frame
		if not q.alive: break
	check(not q.alive and p.velocity.y < 0, "Physical head contact still stomps and bounces")
	var distances: Array = []
	for held in [false, true]:
		reset()
		p.position = Vector2(100, 270)
		q.position = Vector2(800, 507)
		for i in 17:
			p.simulate(DT, {"bits": 2 if held or i == 0 else 0, "aim": Vector2.RIGHT})
			await physics_frame
		distances.append(p.position.x - 100)
	check(distances[1] > distances[0] + 55, "Holding dash travels farther than tapping")
	reset()
	p.position = Vector2(450, 250)
	p.wings = true
	p.simulate(DT, {"bits": 1})
	check(p.air_jump_used and p.velocity.y < -450, "Wings grant an aerial jump")
	p.simulate(DT, {})
	p.simulate(DT, {"bits": 1})
	check(p.velocity.y > -200, "Wings cannot repeat jumps without landing")
	p.shield = true
	var score: int = q.score
	game.kill(p.pid, q.pid)
	check(p.alive and not p.shield and q.score == score, "Shield absorbs one hit without awarding points")
	p.invulnerable = 0
	game.kill(p.pid, q.pid)
	check(not p.alive and q.score == score + 1, "After shield breaks the next hit kills normally")
	reset()
	p.position = Vector2(200, 480)
	q.position = Vector2(800, 480)
	for kind in [3, 4, 2]:
		game.pickups = [{"p": p.position, "kind": kind}]
		game.update_pickups(0)
	check(p.shield and p.wings and p.inventory.has(2), "Chests grant shield, wings and explosive arrows")
	var level: int = game.map_id
	var total: int = p.score
	game.reset_round()
	check(game.map_id == (level + 1) % game.MAPS.size() and p.score == total, "Each round changes arena and preserves score")
	check(not p.shield and not p.wings, "Round reset clears chest powers")
	for index in game.MAPS.size():
		game.build_map(index)
		p.position = Vector2(974, 270)
		p.velocity = Vector2.ZERO
		p.visual_offset = Vector2(0, 100)
		p.dash = 0
		p.simulate(DT, {})
		await physics_frame
		check(p.position.x < 0 and absf(p.position.y - 270) < 1 and p.visual_offset == Vector2.ZERO, "Map %d lateral wrap preserves height and clears smoothing" % index)
	game.queue_free()
	await create_timer(0.2).timeout
	quit(1 if failed else 0)
