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
	game.set_physics_process(false)
	game.practice(true)
	preload("res://tests/fixture.gd").install(game)
	var p = game.players[1]
	game.players[-1].position = Vector2(800, 100)
	await physics_frame
	p.position = Vector2(339, 348)
	p.velocity = Vector2(100, 80)
	for i in 8: p.simulate(1.0 / 60, {"x": 1.0})
	check(p.wall_grabbing and absf(p.velocity.y) < 0.1, "Holding into masonry grips the wall")
	var y: float = p.position.y
	for i in 30: p.simulate(1.0 / 60, {"x": 1.0})
	check(absf(p.position.y - y) < 1, "Wall grip holds height")
	p.simulate(1.0 / 60, {"x": 1.0, "bits": 1})
	check(p.velocity.x < 0 and p.velocity.y < 0, "Jump pushes away from wall")
	p.position = Vector2(339, 348)
	p.velocity = Vector2(100, 50)
	p.wall_lock = 0
	for i in 8: p.simulate(1.0 / 60, {"x": 1.0})
	p.simulate(1.0 / 60, {})
	check(not p.wall_grabbing and p.velocity.y > 0, "Releasing direction releases grip")
	p.position = Vector2(200, 390)
	p.inventory.assign([0])
	for kind in [0, 1, 2]:
		game.projectiles = [{"id": kind + 100, "owner": -1, "p": p.position + Vector2(0, 16), "v": Vector2.DOWN, "kind": kind, "age": 1.0, "stuck": true}]
		game.update_arrows(1.0 / 60)
		check(game.projectiles.is_empty() and p.inventory.back() == kind, "Ground pickup preserves type %d" % kind)
	game.projectiles = [{"id": 200, "owner": -1, "p": Vector2(480, 312), "v": Vector2(0, 700), "kind": 0, "age": 1.0, "stuck": false}]
	game.update_arrows(1.0 / 60)
	check(game.projectiles[0].stuck and game.projectiles[0].p.y <= 320, "Arrow stops at reachable stone surface")
	game.queue_free()
	await create_timer(0.2).timeout
	quit(1 if failed else 0)
