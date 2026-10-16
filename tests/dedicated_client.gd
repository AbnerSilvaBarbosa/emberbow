extends SceneTree
# Joins a dedicated server on localhost and checks the automatic match start
# plus server-side simulation of this client's movement.
var game: Node
var elapsed := 0.0
var connected := false
var started := false
var moved := false
var rotated := false
var initial_x := -10000.0
var finished := false

func _initialize() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child.call_deferred(game)

func _process(dt: float) -> bool:
	if finished: return false
	elapsed += dt
	if not is_instance_valid(game) or not is_instance_valid(game.status): return false
	if not connected and elapsed > 0.8:
		connected = true
		# Send explicit commands; don't race the real keyboard sampler.
		game.set_physics_process(false)
		game.address.text = "127.0.0.1"
		game.join()
	if game.mode == "playing": started = true
	if game.round_number >= 2: rotated = true
	var id := game.multiplayer.get_unique_id()
	if started and game.players.has(id):
		var p: Node = game.players[id]
		if initial_x < -999: initial_x = p.position.x
		if absf(p.position.x - initial_x) > 40: moved = true
		if game.next_round <= 0: game.input_command.rpc_id(1, 1.0, Vector2.RIGHT, 0)
	if rotated or elapsed > 26.0:
		finished = true
		var trace := "DEDICATED_CLIENT_TRACE elapsed=%.1f mode=%s next=%.2f round=%d moved=%s rotated=%s" % [elapsed, game.mode, game.next_round, game.round_number, moved, rotated]
		print(trace)
		if connected and started and moved and rotated:
			print("DEDICATED_CLIENT_PASS: start=%s moved=%s rotated=%s" % [started, moved, rotated])
			finish.call_deferred(0)
		else:
			push_error("DEDICATED_CLIENT_FAIL: connected=%s start=%s moved=%s rotated=%s players=%d mode=%s" % [connected, started, moved, rotated, game.players.size(), game.mode])
			finish.call_deferred(1)
	return false

func finish(code: int) -> void:
	if not game.multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		game.multiplayer.multiplayer_peer.close()
		game.multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	game.queue_free()
	await create_timer(0.2).timeout
	quit(code)
