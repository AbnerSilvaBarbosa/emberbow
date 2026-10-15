extends SceneTree
var game: Node
func _initialize() -> void:
	call_deferred("capture")
func save(name_value: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + name_value + ".png")
func click_at(pos: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	motion.global_position = pos
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = pos
		event.global_position = pos
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
func capture() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await save("menu")
	game.ui.show_page("online")
	await save("online")
	game.ui.show_page("help")
	await save("controls")
	game.ui.show_page("home")
	if "--visual-only" in OS.get_cmdline_user_args():
		game.practice(false)
	else:
		await create_timer(0.3).timeout
		for control in game.ui.pages["home"].get_children():
			if control is Button and control.text == "Treinar contra bot":
				await click_at(control.get_global_rect().get_center())
		assert(game.mode == "playing", "Clicking the training button must start a match")
		print("UI_PASS: mouse click starts training")
	game.local_two = true
	game.set_physics_process(false)
	game.spawn(3)
	game.spawn(4)
	game.next_round = 0
	game.round_time = 8
	for p in game.players.values():
		p.position = game.spawn_point(p.slot)
		p.trail.clear()
		p.dash = 0
	game.players[1].score = 4
	game.players[-1].score = 2
	game.players[3].score = 6
	game.players[4].score = 1
	game.players[3].special = 1
	game.players[1].inventory.assign([0, 1, 2, 0])
	game.players[-1].inventory.assign([2, 0, 1])
	game.players[1].charge = 0.25
	game.players[-1].dash = 0.12
	game.players[-1].cooldown = 0.5
	game.fire(game.players[1])
	game.projectiles[0].p = Vector2(365, 407)
	game.pickups = [{"p": Vector2(480, 304), "kind": 2}]
	game.queue_redraw()
	await create_timer(0.1).timeout
	await save("arena")
	game.record_replay()
	game.round_time += 0.1
	game.record_replay()
	game.next_round = game.SCORE_TIME + 1
	await save("round-replay")
	game.next_round = 0
	game.round_time = 0
	game.next_round = 1.5
	await save("round-intro")
	game.round_time = 8
	game.next_round = 2.0
	game.players[3].round_start_score = 6
	game.players[4].round_start_score = 1
	game.players[1].round_start_score = 3
	game.players[-1].round_start_score = 3
	await save("round-score")
	game.next_round = 0
	game.toggle_pause()
	await save("pause")
	game.menu.hide()
	for index in range(1, game.MAPS.size()):
		game.build_map(index)
		for p in game.players.values():
			p.position = game.spawn_point(p.slot)
			p.trail.clear()
			p.dash = 0
		game.pickups = [{"p": game.spawn_point(2), "kind": 2}]
		game.queue_redraw()
		await save("arena-" + str(index))
	game.build_map(2)
	game.queue_redraw()
	await save("garden")
	game.mode = "finished"
	game.winner = 3
	game.players[3].score = 10
	await save("results")
	game.leave("")
	DisplayServer.window_set_size(Vector2i(1280, 800))
	await create_timer(0.15).timeout
	await save("menu-large")
	game.queue_free()
	await create_timer(0.2).timeout
	quit()
