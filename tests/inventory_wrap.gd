extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if value: print("PASS: " + message)
	else:
		failed = true
		push_error("FAIL: " + message)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.practice(true)
	preload("res://tests/fixture.gd").install(game)
	var p: Node = game.players[1]
	var q: Node = game.players[-1]
	p.collect_special(1)
	check(p.inventory == [1, 1, 0, 0, 0], "Special arrows coexist with normal arrows")
	p.position = Vector2(480, 460)
	p.simulate(1.0 / 60, {"bits": 4})
	p.simulate(1.0 / 60, {"bits": 0})
	check(game.projectiles[0].kind == 1 and p.inventory == [1, 0, 0, 0], "Firing consumes the selected arrow type only")
	p.simulate(1.0 / 60, {"bits": 16})
	check(p.inventory == [0, 0, 0, 1], "Cycling arrows changes the next shot without changing inventory")
	p.inventory.assign([0])
	q.position = Vector2(700, 480)
	p.position = Vector2(300, 480)
	p.dash = 0.15
	p.invulnerable = 0
	game.projectiles = [{"id": 50, "owner": -1, "p": Vector2(280, 480), "v": Vector2(700, 0), "kind": 2, "age": 0.3, "stuck": false}]
	game.update_arrows(1.0 / 60)
	check(p.alive and p.inventory == [0, 2], "Catching a detonating arrow preserves its type")
	p.dash = 0
	p.inventory.assign([0, 0, 0, 0, 0, 0])
	p.collect_special(2)
	check(p.inventory == [2, 2, 0, 0, 0, 0], "Full quiver accepts two specials without exceeding six")
	for map_id in game.MAPS.size():
		game.build_map(map_id)
		await physics_frame
		p.position = Vector2(480, 608)
		p.velocity = Vector2(0, 560)
		p.previous = 0
		p.dash = 0
		p.simulate(1.0 / 60, {})
		check(p.position.y < 90 and p.velocity.y > 0, "Arena %d: falling exits below and returns above with momentum" % map_id)
		p.position = Vector2(971, 270)
		p.velocity = Vector2(245, 0)
		p.simulate(1.0 / 60, {"x": 1.0, "aim": Vector2.RIGHT})
		check(p.position.x < 0, "Arena %d: right edge returns to left" % map_id)
		p.position = Vector2(-11, 270)
		p.velocity = Vector2(-245, 0)
		p.simulate(1.0 / 60, {"x": -1.0, "aim": Vector2.LEFT})
		check(p.position.x > 960, "Arena %d: left edge returns to right" % map_id)
		# Every map has a real opening along the bottom rather than a sealed floor.
		var openings := 0
		for x in range(16, 945, 16):
			var sealed := false
			for rect in game.platforms:
				if rect.position.y >= 576 and x >= rect.position.x and x <= rect.end.x: sealed = true
			if not sealed: openings += 1
		check(openings >= 4, "Arena %d: bottom route contains a usable opening" % map_id)
	p.position = Vector2(100, 120)
	q.position = Vector2(800, 120)
	game.projectiles = [{"id": 88, "owner": 1, "p": Vector2(480, 608), "v": Vector2(0, 700), "kind": 0, "age": 0.3, "stuck": false}]
	game.update_arrows(1.0 / 60)
	check(game.projectiles.size() == 1 and game.projectiles[0].p.y < 90 and not game.projectiles[0].stuck, "Arrows also wrap from bottom to top")
	game.queue_free()
	await create_timer(0.2).timeout
	quit(1 if failed else 0)
