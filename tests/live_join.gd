extends SceneTree
# Joins a server that is already running on 127.0.0.1:24680 and checks that it
# opens the match on its own and simulates this client's movement.
# Usage: godot --headless --path . --script tests/live_join.gd
var game: Node
var elapsed := 0.0
var connected := false
var started := false
var moved := false
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
	var id := game.multiplayer.get_unique_id()
	if started and game.players.has(id):
		var p: Node = game.players[id]
		if initial_x < -999: initial_x = p.position.x
		if absf(p.position.x - initial_x) > 40: moved = true
		if game.next_round <= 0: game.input_command.rpc_id(1, 1.0, Vector2.RIGHT, 0)
	if moved or elapsed > 14.0:
		finished = true
		if connected and started and moved:
			print("LIVE_JOIN_PASS: players=%d" % game.players.size())
			finish.call_deferred(0)
		else:
			push_error("LIVE_JOIN_FAIL: connected=%s started=%s moved=%s players=%d mode=%s" % [connected, started, moved, game.players.size(), game.mode])
			finish.call_deferred(1)
	return false

func finish(code: int) -> void:
	if not game.multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		game.multiplayer.multiplayer_peer.close()
		game.multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	game.queue_free()
	await create_timer(0.2).timeout
	quit(code)
