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
	game.spawn(3)
	game.set_physics_process(false)
	game.next_round = 0
	game.round_time = 1
	game.players[1].score = 9
	game.kill(3, 1)
	check(game.players[3].death_age == 0 and game.shake == 8 and game.audio_nodes.has("death"), "Death starts animation, impact sound and camera shake")
	game.hitstop = 0
	game._physics_process(0.016)
	check(game.next_round == 0 and game.winner == 0, "Two survivors keep playing even after a winning score")
	game.kill(-1, 1)
	game.hitstop = 0
	game._physics_process(0.016)
	check(game.next_round > 7 and game.winner == 1, "One survivor begins death hold and replay sequence")
	check(game.replay_progress() == 1, "Initial hold stays at the final moment")
	game.next_round = game.SCORE_TIME + game.REPLAY_TIME - game.DEATH_HOLD - 0.1
	var a: float = game.replay_progress()
	game.next_round -= 0.3
	check(game.replay_progress() < a, "Rewind moves backward through history")
	game.next_round = game.SCORE_TIME + game.REPLAY_TIME - game.DEATH_HOLD - game.REWIND_TIME - 0.1
	a = game.replay_progress()
	game.next_round -= 0.3
	check(game.replay_progress() > a and game.replay_progress() < 0.2, "Slow motion moves forward gradually")
	game.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failed else 0)
