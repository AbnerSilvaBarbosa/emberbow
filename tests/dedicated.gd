extends SceneTree
# Drives a real dedicated server started with `-- --server` and checks that
# rounds open and rotate without anyone touching the host interface.
var game: Node
var elapsed := 0.0
var listening := false
var auto_started := false
var forced := false
var rotated := false
var rotated_at := 0.0
var finished := false

func _initialize() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child.call_deferred(game)

func _process(dt: float) -> bool:
	if finished: return false
	elapsed += dt
	if not is_instance_valid(game) or not is_instance_valid(game.status): return false
	if game.dedicated and game.mode == "lobby": listening = true
	if listening and game.mode == "playing": auto_started = true
	if auto_started and game.players.size() >= 2 and not forced and elapsed > 11.0:
		for id in game.players:
			game.kill(id, 0)
		forced = true
	if forced and game.round_number >= 2:
		rotated = true
		if rotated_at == 0.0: rotated_at = elapsed
	# Keep the server up briefly after rotating so clients observe the new round.
	if rotated and elapsed > rotated_at + 4.0: finished = true
	if not rotated and elapsed > 30.0: finished = true
	if finished:
		if listening and auto_started and rotated:
			print("DEDICATED_SERVER_PASS: players=%d round=%d" % [game.players.size(), game.round_number])
			finish.call_deferred(0)
		else:
			push_error("DEDICATED_SERVER_FAIL: listening=%s start=%s rotated=%s mode=%s" % [listening, auto_started, rotated, game.mode])
			finish.call_deferred(1)
	return false

func finish(code: int) -> void:
	if not game.multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		game.multiplayer.multiplayer_peer.close()
		game.multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	game.queue_free()
	await create_timer(0.2).timeout
	quit(code)
