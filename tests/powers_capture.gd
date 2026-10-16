extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.practice(true)
	game.set_physics_process(false)
	game.round_time = 2
	game.next_round = 0
	game.players[1].shield = true
	game.players[-1].wings = true
	game.players[1].position = Vector2(280, 300)
	game.players[-1].position = Vector2(680, 300)
	game.pickups = [{"p": Vector2(350, 480), "kind": 3}, {"p": Vector2(610, 480), "kind": 4}]
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/chest-powers.png")
	game.queue_free()
	await create_timer(0.2).timeout
	quit()
