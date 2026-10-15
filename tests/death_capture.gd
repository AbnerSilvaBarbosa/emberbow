extends SceneTree
func _initialize() -> void: run.call_deferred()
func save(name_value: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + name_value + ".png")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.practice(true)
	game.set_physics_process(false)
	game.round_time = 1
	for i in 90:
		game.round_time += 1.0 / 60
		game.players[-1].position = Vector2(580 - i, 330)
		game.record_replay()
	game.kill(-1, 1)
	game.record_replay()
	game.next_round = game.SCORE_TIME + game.REPLAY_TIME - 0.1
	await save("death-impact")
	game.next_round = game.SCORE_TIME + game.REPLAY_TIME - 1.0
	await save("death-rewind")
	game.next_round = game.SCORE_TIME + game.REPLAY_TIME - 2.5
	await save("death-slow-motion")
	game.queue_free()
	await create_timer(0.3).timeout
	quit()
