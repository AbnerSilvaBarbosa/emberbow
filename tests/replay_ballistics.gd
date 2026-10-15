extends SceneTree
var failed := false
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: " + label)
	else:
		failed = true
		push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.practice(true)
	game.set_physics_process(false)
	game.platforms.clear()
	var p = game.players[1]
	var q = game.players[-1]
	q.position = Vector2(100, 100)
	p.position = Vector2(480, 500)
	p.aim = Vector2.UP
	p.invulnerable = 0
	p.score = 2
	game.fire(p)
	var turned := false
	for i in 180:
		game.round_time += 1.0 / 60
		game.record_replay()
		game.update_arrows(1.0 / 60)
		if not game.projectiles.is_empty() and game.projectiles[0].v.y > 0: turned = true
		if not p.alive: break
	check(turned, "Upward arrow reaches apex and falls")
	check(not p.alive and p.score == 1, "Returning own arrow kills shooter and removes one point")
	check(game.replay_frames.size() <= 92, "Replay history stays bounded to 1.5 seconds")
	game.next_round = game.SCORE_TIME + game.REPLAY_TIME - game.DEATH_HOLD - game.REWIND_TIME
	var first: Dictionary = game.replay_frame()
	game.next_round = game.SCORE_TIME + 0.01
	var last: Dictionary = game.replay_frame()
	check(first.time < last.time, "Replay progresses through historical frames")
	check(p.score == 1 and not p.alive, "Replay never mutates authoritative scores or life state")
	game.reset_round()
	check(game.replay_frames.is_empty(), "New round clears old replay")
	game.queue_free()
	await create_timer(0.2).timeout
	quit(1 if failed else 0)
