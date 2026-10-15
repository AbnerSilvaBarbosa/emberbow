extends SceneTree
var game: Node
var elapsed := 0.0
var host_side := false
var started := false
var moved := false
var appearance := false
var mixed_inventory := false
var finishing := false
var initial_x := -10000.0

func _initialize() -> void:
	host_side = "--host-test" in OS.get_cmdline_user_args()
	game = load("res://scenes/main.tscn").instantiate()
	if not host_side: game.selected_skin = 2
	root.add_child.call_deferred(game)

func _process(dt: float) -> bool:
	if finishing: return false
	elapsed += dt
	if elapsed < 1 or not is_instance_valid(game.status): return false
	if host_side:
		if game.players.size() == 4 and not started and elapsed > 1.6:
			game.start_match()
			for player in game.players.values(): player.collect_special(1)
			started = true
			print("HOST_STARTED")
		if started:
			for id in game.players:
				if id > 1:
					var p: Node = game.players[id]
					if initial_x < -999: initial_x = p.position.x
					if absf(p.position.x - initial_x) > 45: moved = true
					if p.skin == 2: appearance = true
					if p.inventory.has(0) and p.inventory.has(1): mixed_inventory = true
	else:
		# Send explicit test commands; don't race the real keyboard sampler.
		game.set_physics_process(false)
		if game.mode == "playing":
			game.input_command.rpc_id(1, 1.0, Vector2.RIGHT, 4 if int(elapsed * 10) % 2 == 0 else 0)
			var id := game.multiplayer.get_unique_id()
			if game.players.has(id):
				var p: Node = game.players[id]
				if initial_x < -999: initial_x = p.position.x
				if absf(p.position.x - initial_x) > 45: moved = true
				if p.skin == 2: appearance = true
				if p.inventory.has(0) and p.inventory.has(1): mixed_inventory = true
	if elapsed > (9.0 if host_side else 6.5):
		finishing = true
		if moved and appearance and mixed_inventory:
			print("NETWORK_PASS: ", "host" if host_side else "client")
			finish.call_deferred(0)
		else:
			push_error("NETWORK_FAIL: movement=%s skin=%s inventory=%s" % [moved, appearance, mixed_inventory])
			finish.call_deferred(1)
	return false

func finish(code: int) -> void:
	game.multiplayer.multiplayer_peer.close()
	game.multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	game.queue_free()
	await create_timer(0.2).timeout
	quit(code)
