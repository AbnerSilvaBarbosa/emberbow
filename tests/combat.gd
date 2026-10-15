extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		push_error("FAIL: " + label)
		quit(1)
		assert(value, label)
	print("PASS: " + label)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.practice(true)
	preload("res://tests/fixture.gd").install(game)
	var p = game.players[1]
	var q = game.players[-1]
	p.invulnerable = 0
	q.invulnerable = 0
	p.position = Vector2(200, 480)
	q.position = Vector2(300, 480)
	p.aim = Vector2.RIGHT
	game.fire(p)
	for i in 10: game.update_arrows(1.0 / 60)
	check(not q.alive and p.score == 1, "Arrow hit awards one elimination")
	game.reset_round()
	p.position = Vector2(200, 480)
	q.position = Vector2(300, 480)
	q.invulnerable = 0
	q.dash = 0.15
	q.arrows = 2
	game.fire(p)
	for i in 10: game.update_arrows(1.0 / 60)
	check(q.alive and q.arrows == 3, "Dash captures projectile without damage")
	game.reset_round()
	p.position = Vector2(300, 480)
	q.position = Vector2(350, 480)
	p.invulnerable = 0
	q.invulnerable = 0
	p.special = 2
	game.fire(p)
	game.detonate(1)
	check(not q.alive and not p.alive, "Remote explosion damages opponents and owner")
	game.reset_round()
	p.position = Vector2(300, 450)
	q.position = Vector2(300, 475)
	p.velocity.y = 200
	q.invulnerable = 0
	game.stomps()
	check(not q.alive and p.velocity.y < 0, "Stomp kills and bounces attacker")
	game.reset_round()
	p.special = 1
	p.position = Vector2(330, 331)
	p.aim = Vector2.RIGHT
	game.fire(p)
	game.update_arrows(1.0 / 60)
	check(not game.projectiles[0].stuck, "Drill arrow passes through terrain")
	p.special = 0
	game.projectiles.clear()
	game.fire(p)
	game.update_arrows(1.0 / 60)
	check(game.projectiles[0].stuck, "Normal arrow stops at terrain")
	game.projectiles[0].p = p.position
	game.projectiles[0].age = 1
	p.arrows = 0
	game.update_arrows(1.0 / 60)
	check(p.arrows == 1 and game.projectiles.is_empty(), "Stuck arrow can be recovered")
	game.reset_round()
	p.position = Vector2(320, 507)
	q.alive = false
	for i in 5:
		p.simulate(1.0 / 60, {})
		await physics_frame
	var apex: float = p.position.y
	for i in 40:
		p.simulate(1.0 / 60, {"x": 0.0, "aim": Vector2.RIGHT, "bits": 1})
		await physics_frame
		apex = minf(apex, p.position.y)
	check(apex < 390, "Held jump reaches arena platform height")
	game.queue_free()
	await create_timer(0.2).timeout
	quit()
