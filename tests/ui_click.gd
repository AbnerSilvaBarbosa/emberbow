extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(0.3).timeout
	var button: Button
	for child in game.ui.home.get_children():
		if child is Button and child.text == "Treinar contra bot": button = child
	var pos: Vector2 = button.get_global_rect().get_center()
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
	var ok: bool = game.mode == "playing"
	print("UI_PASS" if ok else "UI_FAIL", " mode=", game.mode, " pos=", pos, " hovered=", root.gui_get_hovered_control())
	game.queue_free()
	await create_timer(0.2).timeout
	quit(0 if ok else 1)
