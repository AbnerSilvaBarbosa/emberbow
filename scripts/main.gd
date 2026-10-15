extends Node2D

const Layouts = preload("res://scripts/arena_layouts.gd")
const Gamepad = preload("res://scripts/gamepad.gd")
const Art = preload("res://scripts/art.gd")
const Interface = preload("res://scripts/interface.gd")
const Archer = preload("res://scripts/player.gd")
const PORT := 24680
const COLORS := [Color("65e0b6"), Color("ffb55c"), Color("c8a0fa"), Color("ed748b")]
const MAPS := ["Ruínas da Aurora", "Forja Suspensa", "Jardim Lunar", "Abismo Astral", "Torres Gêmeas", "Coroa Partida", "Pátio Cruzado", "Forja em Zigue-zague", "Jardim das Ilhas", "Galerias do Abismo", "Pontes Gêmeas", "Coroa Dividida"]
var art := Art.new()
var ui: CanvasLayer
var selected_skin := 0
var visual_time := 0.0
var screen_shake := true
var shake := 0.0
var hitstop := 0.0
var camera: Camera2D
var mouse_aim_until := 0
const SCORE_TIME := 3.4
const REPLAY_TIME := 4.6
const DEATH_HOLD := 0.7
const REWIND_TIME := 0.7
var replay_frames: Array = []
var round_number := 0
var bot_jump_until := 0
var bot_shoot_until := 0
var players: Dictionary = {}
var commands: Dictionary = {}
var projectiles: Array = []
var platforms: Array[Rect2] = []
var terrain: Node2D
var menu: Control
var status: Label
var address: LineEdit
var map_select: OptionButton
var hud: Label
var banner: Label
var mode := "menu"
var map_id := 0
var round_time := 0.0
var next_round := 0.0
var winner := 0
var tick := 0
var arrow_id := 0
var particle_events: Array = []
var audio_nodes: Dictionary = {}
var music: AudioStreamPlayer
var music_on := true
var local_two := false
var notice := ""
var net_clock := 0.0
var event_seq := 0
var seen_event := 0
var pickups: Array = []
var pickup_timer := 0.0
var chest_cycle := 0

func _ready() -> void:
	Gamepad.configure_menu()
	RenderingServer.set_default_clear_color(Color("0b151e"))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	camera = Camera2D.new()
	camera.position = Vector2(480, 300)
	add_child(camera)
	terrain = Node2D.new()
	add_child(terrain)
	build_map(0)
	build_ui()
	Input.joy_connection_changed.connect(controller_connection_changed)
	for key in ["shoot", "catch", "jump", "dash", "hit", "blast", "ui", "death"]:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://audio/" + key + ".wav")
		player.volume_db = -15
		add_child(player)
		audio_nodes[key] = player
	music = AudioStreamPlayer.new()
	music.stream = load("res://audio/music.wav")
	music.volume_db = -25
	music.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.stream.loop_end = int(music.stream.get_length() * music.stream.mix_rate)
	add_child(music)
	music.play()
	multiplayer.peer_connected.connect(peer_joined)
	multiplayer.peer_disconnected.connect(peer_left)
	multiplayer.connected_to_server.connect(func():
		status.text = "Conectado. Aguardando o anfitrião iniciar."
		choose_skin.rpc_id(1, selected_skin))
	multiplayer.connection_failed.connect(func(): leave("Não foi possível conectar. Confira IP e porta UDP."))
	multiplayer.server_disconnected.connect(func(): leave("O anfitrião encerrou a sala."))
	var args := OS.get_cmdline_user_args()
	if "--host-test" in args:
		host()
	if "--join-test" in args:
		address.text = "127.0.0.1"
		join()
	if "--practice-test" in args:
		practice(false)

func build_ui() -> void:
	ui = Interface.new()
	add_child(ui)
	ui.build(self)

func map_rects(index: int) -> Array[Rect2]:
	return Layouts.rectangles(index)

func build_map(index: int) -> void:
	map_id = index
	for child in terrain.get_children(): child.free()
	platforms = map_rects(index)
	for rect in platforms:
		var solid := StaticBody2D.new()
		solid.position = rect.get_center()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		solid.add_child(shape)
		terrain.add_child(solid)

func spawn_point(slot: int) -> Vector2:
	return Layouts.spawn_at(map_id, slot)

func spawn(id: int) -> void:
	if players.has(id): return
	var p := Archer.new()
	p.pid = id
	var used_slots: Array = players.values().map(func(other): return other.slot)
	p.slot = 0
	while used_slots.has(p.slot): p.slot += 1
	p.skin = selected_skin if id == 1 else (selected_skin + p.slot) % 4
	p.tint = COLORS[p.slot % 4]
	p.arena = self
	add_child(p)
	players[id] = p
	p.position = spawn_point(p.slot)

func clear_players() -> void:
	for p in players.values(): p.free()
	players.clear()
	commands.clear()
	projectiles.clear()

func practice(two: bool) -> void:
	leave("")
	local_two = two
	spawn(1)
	spawn(-1)
	start_match()

func host() -> void:
	leave("")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, 3)
	if error != OK:
		status.text = "Erro ao abrir a porta: " + error_string(error)
		return
	multiplayer.multiplayer_peer = peer
	spawn(1)
	mode = "lobby"
	ui.show_page("lobby")
	status.text = "Sala aberta · 1/4 · UDP 24680. Compartilhe seu IP."

func join() -> void:
	var ip := address.text.strip_edges()
	leave("")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip, PORT)
	if error != OK:
		ui.show_page("online")
		status.text = "Endereço inválido: " + error_string(error)
		return
	multiplayer.multiplayer_peer = peer
	mode = "connecting"
	ui.show_page("lobby")
	status.text = "Conectando a " + ip + "…"

func leave(message: String) -> void:
	replay_frames.clear()
	if not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	clear_players()
	mode = "menu"
	local_two = false
	notice = ""
	hitstop = 0
	shake = 0
	seen_event = 0
	event_seq = 0
	next_round = 0
	round_time = 0
	particle_events.clear()
	pickups.clear()
	ui.show_page("home")
	build_map(map_select.selected)
	status.text = message
	banner.text = ""

func peer_joined(id: int) -> void:
	if not multiplayer.is_server(): return
	if mode == "playing" or mode == "finished":
		(multiplayer.multiplayer_peer as ENetMultiplayerPeer).disconnect_peer(id)
		return
	spawn(id)
	status.text = "Sala aberta · %d/4. Pronto para iniciar." % players.size()
	broadcast()

func peer_left(id: int) -> void:
	if players.has(id):
		players[id].free()
		players.erase(id)
	commands.erase(id)
	if multiplayer.is_server() and mode == "playing" and players.size() < 2:
		mode = "lobby"
		menu.show()
		status.text = "Jogador saiu. Aguardando adversário."

func start_match() -> void:
	if not multiplayer.is_server() or players.size() < 2:
		status.text = "É preciso ter pelo menos dois jogadores na sala."
		return
	build_map(map_select.selected)
	for p in players.values(): p.score = 0
	winner = 0
	round_number = 0
	notice = ""
	mode = "playing"
	reset_round()
	menu.hide()
	if multiplayer.has_multiplayer_peer(): broadcast()

func reset_round() -> void:
	replay_frames.clear()
	round_number += 1
	projectiles.clear()
	pickups.clear()
	pickup_timer = 4
	chest_cycle = 0
	round_time = 0
	next_round = 2.4
	for p in players.values():
		p.round_start_score = p.score
		p.alive = true
		p.death_age = 10
		p.arrows = 3
		p.special = 0
		p.position = spawn_point(p.slot)
		p.velocity = Vector2.ZERO
		p.dash = 0
		p.cooldown = 0
		p.previous = 0
		p.invulnerable = 0.5
		p.charge = 0
		p.coyote = 0
		p.jump_buffer = 0
		p.jump_consumed = false
		p.shoot_cd = 0
		p.wall_lock = 0
		p.trail.clear()
		p.visual_offset = Vector2.ZERO
		p.facing = 1 if p.slot % 2 == 0 else -1
		p.aim = Vector2(p.facing, 0)

func controls(second := false) -> Dictionary:
	var left := KEY_LEFT if second else KEY_A
	var right := KEY_RIGHT if second else KEY_D
	var up := KEY_UP if second else KEY_W
	var down := KEY_DOWN if second else KEY_S
	var axis := float(Input.is_physical_key_pressed(right)) - float(Input.is_physical_key_pressed(left))
	var vertical := float(Input.is_physical_key_pressed(down)) - float(Input.is_physical_key_pressed(up))
	var aim := Vector2(axis, vertical)
	var bits := 0
	if Input.is_physical_key_pressed(KEY_ENTER if second else KEY_SPACE) or (second and Input.is_physical_key_pressed(KEY_KP_0)): bits |= 1
	if Input.is_physical_key_pressed(KEY_CTRL if second else KEY_K) or (second and Input.is_physical_key_pressed(KEY_KP_2)): bits |= 2
	if Input.is_physical_key_pressed(KEY_SHIFT if second else KEY_J) or (second and Input.is_physical_key_pressed(KEY_KP_1)): bits |= 4
	if Input.is_physical_key_pressed(KEY_BACKSPACE if second else KEY_L) or (second and Input.is_physical_key_pressed(KEY_KP_3)): bits |= 8
	if Input.is_physical_key_pressed(KEY_PERIOD if second else KEY_R): bits |= 16
	if not second:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): bits |= 4
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): bits |= 2
		var local_id := multiplayer.get_unique_id()
		if Time.get_ticks_msec() < mouse_aim_until and players.has(local_id):
			aim = (get_global_mouse_position() - players[local_id].global_position).normalized()
	var device := Gamepad.device_for(Array(Input.get_connected_joypads()), local_two, second)
	if device >= 0:
		var pad := Gamepad.sample(device)
		if absf(pad.x) > 0: axis = pad.x
		if pad.aim != Vector2.ZERO: aim = pad.aim
		bits |= pad.bits
	return {"x": axis, "aim": aim, "bits": bits}

func bot(p: Node) -> Dictionary:
	var target: Node = players.get(1)
	if target == null or not target.alive: return {}
	var diff: Vector2 = target.position - p.position
	var bits := 0
	var axis := signf(diff.x) if absf(diff.x) > 150 else 0.0
	# Recover ammunition before chasing an impossible shot.
	if p.arrows == 0:
		var nearest := 10000.0
		for a in projectiles:
			if a.stuck and p.position.distance_to(a.p) < nearest:
				nearest = p.position.distance_to(a.p)
				axis = signf(a.p.x - p.position.x)
	var query := PhysicsRayQueryParameters2D.create(p.position, target.position, 1)
	var clear_shot := get_world_2d().direct_space_state.intersect_ray(query).is_empty()
	if p.is_on_floor() and (diff.y < -35 or not clear_shot) and tick % 50 == 0:
		bot_jump_until = tick + 23
	if p.is_on_wall() and tick % 20 == 0: bot_jump_until = tick + 23
	if tick < bot_jump_until: bits |= 1
	if tick % 62 == 0 and diff.length() < 680 and clear_shot: bot_shoot_until = tick + 10
	if tick < bot_shoot_until: bits |= 4
	if tick % 103 == 0: bits |= 8
	for a in projectiles:
		if a.owner != p.pid and a.p.distance_to(p.position) < 70 and not a.stuck and tick % 3 == 0: bits |= 2
	var predicted: Vector2 = diff + target.velocity * minf(0.12, diff.length() / 720)
	return {"x": axis, "aim": predicted.normalized(), "bits": bits}

@rpc("any_peer", "call_remote", "reliable", 3)
func choose_skin(value: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if multiplayer.is_server() and mode == "lobby" and players.has(id): players[id].skin = clampi(value, 0, 3)

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func input_command(x: float, aim: Vector2, bits: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not multiplayer.is_server() or not players.has(id): return
	if not is_finite(x) or not is_finite(aim.x) or not is_finite(aim.y): return
	commands[id] = {"x": clampf(x, -1, 1), "aim": aim.limit_length(1), "bits": bits & 31, "time": Time.get_ticks_msec()}

func _physics_process(dt: float) -> void:
	tick += 1
	visual_time += dt
	shake = maxf(0, shake - dt * 24)
	camera.offset = Vector2(sin(tick * 2.3), cos(tick * 3.7)) * shake if screen_shake else Vector2.ZERO
	for event in particle_events: event.life -= dt
	particle_events = particle_events.filter(func(e): return e.life > 0)
	if mode == "playing":
		var cmd: Dictionary = controls() if not menu.visible else {"x": 0.0, "aim": Vector2.ZERO, "bits": 0}
		if multiplayer.is_server(): commands[1] = cmd
		else: input_command.rpc_id(1, cmd.x, cmd.aim, cmd.bits)
	var local_paused := menu.visible and multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	hitstop = maxf(0, hitstop - dt)
	if multiplayer.is_server() and mode == "playing" and not local_paused and hitstop <= 0:
		if next_round > 0:
			next_round -= dt
			if next_round <= 0 and round_time > 0:
				if winner != 0:
					mode = "finished"
					menu.show()
				else: reset_round()
		else:
			round_time += dt
			for p in players.values():
				var cmd: Dictionary = commands.get(p.pid, {})
				if p.pid == -1: cmd = controls(true) if local_two else bot(p)
				if p.pid > 1 and Time.get_ticks_msec() - cmd.get("time", 0) > 300: cmd = {}
				p.simulate(dt, cmd)
			update_arrows(dt)
			update_pickups(dt)
			stomps()
			if round_time > 40:
				var inset := (round_time - 40) * 12
				for p in players.values():
					if p.alive and (p.position.x < inset or p.position.x > 960 - inset): kill(p.pid, 0)
			var living := players.values().filter(func(p): return p.alive)
			record_replay()
			if living.size() <= 1:
				next_round = SCORE_TIME + REPLAY_TIME
				for p in players.values():
					if p.score >= 10: winner = p.pid
	if multiplayer.is_server() and mode != "menu":
		net_clock += dt
		if net_clock >= 1.0 / 30:
			net_clock = 0
			broadcast()
	update_hud()
	queue_redraw()

func record_replay() -> void:
	var actors: Array = []
	for p in players.values():
		actors.append({"p": p.position, "v": p.velocity, "alive": p.alive, "skin": p.skin, "facing": p.facing, "aim": p.aim, "tint": p.tint, "inventory": p.inventory.duplicate()})
	replay_frames.append({"time": round_time, "actors": actors, "arrows": projectiles.duplicate(true), "effects": particle_events.duplicate(true)})
	while replay_frames.size() > 1 and round_time - replay_frames[0].time > 1.5: replay_frames.pop_front()

func replay_elapsed() -> float:
	return clampf(SCORE_TIME + REPLAY_TIME - next_round, 0, REPLAY_TIME)

func replay_progress() -> float:
	var elapsed := replay_elapsed()
	if elapsed < DEATH_HOLD: return 1.0
	if elapsed < DEATH_HOLD + REWIND_TIME:
		return 1.0 - (elapsed - DEATH_HOLD) / REWIND_TIME
	return clampf((elapsed - DEATH_HOLD - REWIND_TIME) / 2.8, 0, 1)

func replay_frame() -> Dictionary:
	if replay_frames.is_empty(): return {}
	var progress := replay_progress()
	var target: float = lerpf(replay_frames[0].time, replay_frames[-1].time, progress)
	var result: Dictionary = replay_frames[0]
	for frame in replay_frames:
		if frame.time > target: break
		result = frame
	return result

func fire(p: Node, kind := -1) -> void:
	arrow_id += 1
	projectiles.append({"id": arrow_id, "owner": p.pid, "p": p.position + p.aim * 22, "v": p.aim * (700 + p.charge * 120), "kind": p.special if kind < 0 else kind, "age": 0.0, "stuck": false})
	effect(p.position + p.aim * 18, p.tint, "shoot")

func update_arrows(dt: float) -> void:
	var removed: Array = []
	for a in projectiles:
		a.age += dt
		if a.age > 18:
			removed.append(a.id)
			continue
		if not a.stuck:
			var old: Vector2 = a.p
			a.v.y += 650 * dt
			a.p += a.v * dt
			a.p.x = wrapf(a.p.x, -16, 976)
			if absf(a.p.x - old.x) > 500: old = a.p
			if a.p.y > 612:
				a.p.y = -12
				old = a.p
			elif a.p.y < -12:
				a.p.y = 612
				old = a.p
			if a.kind != 1:
				for rect in platforms:
					if rect.has_point(a.p):
						# Keep a stuck arrow on the reachable surface, not buried in masonry.
						var outside: Vector2 = old
						var inside: Vector2 = a.p
						for step in 10:
							var midpoint := (outside + inside) * 0.5
							if rect.has_point(midpoint): inside = midpoint
							else: outside = midpoint
						a.p = outside
						a.stuck = true
						break
			if a.stuck: continue
			for p in players.values():
				if not p.alive or (p.pid == a.owner and a.age < 0.18): continue
				var nearest := Geometry2D.get_closest_point_to_segment(p.position, old, a.p)
				if nearest.distance_to(p.position) < 16:
					if p.dash > 0:
						p.collect_arrow(a.kind)
						removed.append(a.id)
						effect(p.position, p.tint, "catch", "CAPTUROU!")
						p.cooldown = minf(p.cooldown, 0.18)
						hitstop = 0.035
					elif p.invulnerable <= 0:
						kill(p.pid, a.owner)
						removed.append(a.id)
					break
		else:
			for p in players.values():
				if p.alive and p.arrows < 6 and p.position.distance_to(a.p) < 24 and a.age > 0.25:
					p.collect_arrow(a.kind)
					effect(p.position, p.tint, "pickup", "+1 FLECHA")
					removed.append(a.id)
					break
	projectiles = projectiles.filter(func(a): return not removed.has(a.id))

func detonate(id: int) -> void:
	var bombs := projectiles.filter(func(a): return a.owner == id and a.kind == 2)
	for a in bombs:
		effect(a.p, Color("ffb55c"), "blast")
		for p in players.values():
			if p.alive and p.position.distance_to(a.p) < 76 and p.dash <= 0 and p.invulnerable <= 0: kill(p.pid, id)
	projectiles = projectiles.filter(func(a): return not (a.owner == id and a.kind == 2))

func update_pickups(dt: float) -> void:
	pickup_timer -= dt
	if pickup_timer <= 0:
		pickup_timer = 8
		if pickups.size() < 4:
			var kind := 1 + chest_cycle % 2
			for index in [2, 3]:
				var pos := spawn_point(index)
				if not pickups.any(func(item): return item.p == pos): pickups.append({"p": pos, "kind": kind})
			chest_cycle += 1
	for item in pickups.duplicate():
		for p in players.values():
			if p.alive and p.position.distance_to(item.p) < 28:
				p.collect_special(item.kind)
				pickups.erase(item)
				effect(item.p, p.tint, "catch", "PERFURANTE" if item.kind == 1 else "DETONÁVEL")
				break

func stomps() -> void:
	for p in players.values():
		if not p.alive or p.velocity.y < 90: continue
		for q in players.values():
			if p == q or not q.alive or q.invulnerable > 0 or q.dash > 0: continue
			var diff: Vector2 = q.position - p.position
			if absf(diff.x) < 18 and diff.y > 15 and diff.y < 31:
				kill(q.pid, p.pid)
				p.velocity.y = -280

func kill(victim: int, attacker: int) -> void:
	if not players.has(victim) or not players[victim].alive: return
	var p: Node = players[victim]
	p.alive = false
	p.begin_death()
	sound("death")
	if players.has(attacker):
		players[attacker].score = maxi(0, players[attacker].score + (1 if attacker != victim else -1))
	effect(p.position, p.tint, "hit")
	shake = 8.0
	hitstop = 0.09
	# Eliminated archers drop their remaining ammunition.
	for i in p.inventory.size():
		arrow_id += 1
		projectiles.append({"id": arrow_id, "owner": victim, "p": p.position + Vector2((i - 1) * 12, 8), "v": Vector2.RIGHT, "kind": p.inventory[i], "age": 0.5, "stuck": true})

func sound(key: String) -> void:
	if audio_nodes.has(key): audio_nodes[key].play()

func effect(pos: Vector2, color: Color, key: String, text_value := "") -> void:
	event_seq += 1
	var duration := 0.65 if not text_value.is_empty() else 0.45
	particle_events.append({"p": pos, "c": color, "life": duration, "duration": duration, "key": key, "seq": event_seq, "text": text_value})
	sound(key)

func broadcast() -> void:
	if multiplayer.get_peers().is_empty(): return
	var state: Array = []
	for p in players.values():
		state.append({"id": p.pid, "slot": p.slot, "p": p.position, "v": p.velocity, "alive": p.alive, "arrows": p.arrows, "score": p.score, "round_start_score": p.round_start_score, "aim": p.aim, "dash": p.dash, "special": p.special, "skin": p.skin, "cooldown": p.cooldown, "charge": p.charge, "facing": p.facing, "invulnerable": p.invulnerable, "inventory": p.inventory.duplicate()})
	var visual_arrows: Array = []
	for a in projectiles:
		visual_arrows.append({"p": a.p, "v": a.v, "kind": a.kind, "stuck": a.stuck})
	var packet := var_to_bytes([state, visual_arrows, pickups, mode, map_id, round_time, next_round, winner, particle_events, round_number]).compress(FileAccess.COMPRESSION_DEFLATE)
	receive_snapshot.rpc(packet)

@rpc("authority", "call_remote", "unreliable_ordered", 2)
func receive_snapshot(packet: PackedByteArray) -> void:
	if packet.size() > 8192: return
	var unpacked := packet.decompress_dynamic(65536, FileAccess.COMPRESSION_DEFLATE)
	if unpacked.is_empty(): return
	var data: Variant = bytes_to_var(unpacked)
	if not data is Array or data.size() != 10: return
	round_number = data[9]
	snapshot(data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8])

func snapshot(state: Array, arrows_state: Array, item_state: Array, phase: String, level: int, elapsed: float, delay: float, winning: int, events: Array) -> void:
	if level != map_id: build_map(level)
	var ids: Array = []
	for data in state:
		ids.append(data.id)
		spawn(data.id)
		var p: Node = players[data.id]
		p.slot = data.slot
		p.tint = COLORS[p.slot % 4]
		var old_visual: Vector2 = p.position + p.visual_offset
		p.position = data.p
		p.visual_offset = old_visual - p.position if old_visual.distance_to(p.position) < 140 else Vector2.ZERO
		p.velocity = data.v
		if p.alive and not data.alive: p.begin_death()
		p.alive = data.alive
		p.arrows = data.arrows
		p.score = data.score
		p.round_start_score = data.get("round_start_score", data.score)
		p.aim = data.aim
		p.dash = data.dash
		p.inventory.assign(data.inventory)
		p.skin = data.skin
		p.cooldown = data.cooldown
		p.charge = data.charge
		p.facing = data.facing
		p.invulnerable = data.invulnerable
		p.queue_redraw()
	for id in players.keys():
		if not ids.has(id):
			players[id].free()
			players.erase(id)
	projectiles = arrows_state
	pickups = item_state
	mode = phase
	var was_live := next_round <= 0
	if elapsed < round_time: replay_frames.clear()
	round_time = elapsed
	next_round = delay
	if phase == "playing" and elapsed > 0 and (delay <= 0 or was_live): record_replay()
	winner = winning
	if phase == "playing" and menu.visible and notice != "paused": menu.hide()
	if phase == "finished":
		menu.show()
		status.text = "Partida encerrada. Aguardando revanche do anfitrião."
	for event in events:
		if event.seq > seen_event:
			seen_event = event.seq
			particle_events.append(event)
			sound(event.key)
			if event.key in ["hit", "blast"]: shake = 8.0
			if event.key == "hit": sound("death")

func update_hud() -> void:
	pass # Interface owns HUD state and typography.

func toggle_pause() -> void:
	if mode != "playing": return
	if menu.visible:
		ui.resume()
	else:
		notice = "paused"
		ui.show_page("paused")

func controller_connection_changed(_device: int, connected: bool) -> void:
	if not connected and mode == "playing" and not menu.visible:
		toggle_pause()
	if menu.visible:
		status.text = "Controle conectado." if connected else "Controle desconectado. Reconecte ou use o teclado."

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B and menu.visible:
		if mode == "playing":
			if ui.current_page == "help": ui.show_page("paused")
			else: ui.resume()
		elif mode == "menu": ui.show_page("home")
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.relative.length() > 1 and mode == "playing" and not menu.visible:
		mouse_aim_until = Time.get_ticks_msec() + 2500
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		toggle_pause()
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE:
		if mode == "playing": toggle_pause()
		elif mode == "menu": ui.show_page("home")
	if event.keycode == KEY_M: ui.toggle_music()
	if event.keycode == KEY_F11:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _draw() -> void:
	art.draw_arena(self, self)

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for player in audio_nodes.values():
		if is_instance_valid(player):
			player.stop()
			player.stream = null
