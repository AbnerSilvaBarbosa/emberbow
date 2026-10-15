extends SceneTree
const Pad = preload("res://scripts/gamepad.gd")
var failed := false
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: " + label)
	else:
		failed = true
		push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	check(Pad.device_for([], false, false) == -1, "No controller leaves keyboard available")
	check(Pad.device_for([4], false, false) == 4, "Solo/online uses first connected controller")
	check(Pad.device_for([4], true, false) == -1 and Pad.device_for([4], true, true) == 4, "One local controller belongs only to P2")
	check(Pad.device_for([4, 7], true, false) == 4 and Pad.device_for([4, 7], true, true) == 7, "Two local controllers have separate players")
	var state := Pad.decode(Vector2(0.1, 0.1), Vector2.ZERO, Vector2.ZERO, 0, 0)
	check(state.x == 0 and state.aim == Vector2.ZERO, "Deadzone rejects stick drift")
	state = Pad.decode(Vector2.RIGHT, Vector2.UP, Vector2.ZERO, 1 | 2 | 8 | 16, 0.8)
	check(state.x == 1 and state.aim == Vector2.UP and state.bits == 31, "Independent aim and all combat buttons including trigger")
	state = Pad.decode(Vector2.RIGHT, Vector2.ZERO, Vector2.LEFT, 0, 0)
	check(state.x == -1 and state.aim == Vector2.LEFT, "D-pad overrides movement stick")
	check(Pad.decode(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, 0, 0).bits == 0, "Releasing trigger releases shoot")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var button: Button
	for child in game.ui.home.get_children():
		if child is Button and child.text == "Treinar contra bot": button = child
	button.grab_focus()
	await process_frame
	for pressed in [true, false]:
		var accept := InputEventJoypadButton.new()
		accept.button_index = JOY_BUTTON_A
		accept.pressed = pressed
		root.push_input(accept, true)
		await process_frame
	check(game.mode == "playing", "Controller A activates focused menu button")
	game.practice(true)
	game.set_physics_process(false)
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_START
	event.pressed = true
	game._input(event)
	check(game.menu.visible, "Start opens pause")
	event.button_index = JOY_BUTTON_B
	game._unhandled_input(event)
	check(not game.menu.visible, "B resumes from pause")
	game.controller_connection_changed(4, false)
	check(game.menu.visible and game.status.text.contains("desconectado"), "Disconnect pauses local game with explanation")
	game.queue_free()
	await create_timer(0.2).timeout
	quit(1 if failed else 0)
