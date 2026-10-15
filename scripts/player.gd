extends CharacterBody2D

const RUN_SPEED := 245.0
const JUMP_SPEED := 495.0
const GRAVITY := 980.0
const DASH_SPEED := 570.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.60
var pid: int
var slot: int
var skin := 0
var inventory: Array[int] = [0, 0, 0]
var arrows: int:
	get: return inventory.size()
	set(value):
		while inventory.size() < clampi(value, 0, 6): inventory.append(0)
		while inventory.size() > clampi(value, 0, 6): inventory.pop_back()
var score := 0
var round_start_score := 0
var alive := true
var death_age := 10.0
var facing := 1.0
var aim := Vector2.RIGHT
var dash := 0.0
var cooldown := 0.0
var shoot_cd := 0.0
var coyote := 0.0
var jump_buffer := 0.0
var special: int:
	get: return inventory[0] if not inventory.is_empty() else 0
	set(value):
		if value == 0: inventory.fill(0)
		elif not inventory.is_empty(): inventory[0] = clampi(value, 0, 2)
var previous := 0
var invulnerable := 0.0
var tint := Color.WHITE
var arena: Node
var charge := 0.0
var wall_lock := 0.0
var wall_grabbing := false
var trail: Array = []
var visual_offset := Vector2.ZERO
var anim_time := 0.0
var squash := Vector2.ONE
var was_grounded := false
var jump_consumed := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(18, 26)
	shape.shape = box
	add_child(shape)
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 3.0
	z_index = 3

func _process(dt: float) -> void:
	anim_time += dt
	death_age += dt
	visual_offset = visual_offset.lerp(Vector2.ZERO, 1.0 - exp(-22.0 * dt))
	squash = squash.lerp(Vector2.ONE, 1.0 - exp(-16.0 * dt))
	for ghost in trail: ghost.life -= dt
	trail = trail.filter(func(g): return g.life > 0)
	if dash > 0 and alive:
		trail.append({"p": position + visual_offset, "life": 0.16})
	queue_redraw()

func simulate(dt: float, command: Dictionary) -> void:
	if not alive: return
	var bits: int = command.get("bits", 0)
	var pressed := bits & ~previous
	var released := previous & ~bits
	previous = bits
	cooldown = maxf(0, cooldown - dt)
	shoot_cd = maxf(0, shoot_cd - dt)
	invulnerable = maxf(0, invulnerable - dt)
	wall_lock = maxf(0, wall_lock - dt)
	if is_on_floor():
		if velocity.y >= 0: jump_consumed = false
		coyote = 0.10 if not jump_consumed else 0.0
	else: coyote = maxf(0, coyote - dt)
	jump_buffer = 0.12 if pressed & 1 else maxf(0, jump_buffer - dt)
	var axis: float = command.get("x", 0.0)
	var direction: Vector2 = command.get("aim", Vector2.ZERO)
	if direction.length() > 0.1:
		aim = direction.normalized()
		if absf(aim.x) > 0.15: facing = signf(aim.x)
	elif axis != 0:
		facing = signf(axis)
		aim = Vector2(facing, 0)
	if pressed & 2 and cooldown <= 0:
		wall_grabbing = false
		dash = DASH_TIME
		cooldown = DASH_COOLDOWN
		charge = 0
		velocity = (direction.normalized() if direction.length() > 0.1 else Vector2(facing, 0)) * DASH_SPEED
		arena.effect(position, tint, "dash")
	if dash > 0:
		dash = maxf(0, dash - dt)
		if dash == 0: velocity *= 0.5
	else:
		if wall_lock <= 0:
			var speed := RUN_SPEED * (0.62 if charge > 0 else 1.0)
			velocity.x = move_toward(velocity.x, axis * speed, (2600 if is_on_floor() else 1600) * dt)
		velocity.y = minf(velocity.y + GRAVITY * dt, 560)
		wall_grabbing = is_on_wall() and not is_on_floor() and wall_lock <= 0 and axis * get_wall_normal().x < -0.1 and velocity.y >= 0
		if wall_grabbing:
			velocity.y = 0.0
		if jump_buffer > 0 and (coyote > 0 or is_on_wall()):
			wall_grabbing = false
			velocity.y = -JUMP_SPEED
			if is_on_wall() and not is_on_floor():
				velocity.x = get_wall_normal().x * 310
				wall_lock = 0.14
			jump_buffer = 0
			coyote = 0
			jump_consumed = true
			squash = Vector2(0.8, 1.15)
			arena.effect(position + Vector2(0, 13), tint, "jump")
		if not bits & 1 and velocity.y < -190: velocity.y = -190
	if bits & 4 and arrows > 0 and shoot_cd <= 0 and dash <= 0:
		charge = minf(0.4, charge + dt)
	if released & 4 and charge > 0:
		if arrows > 0 and shoot_cd <= 0:
			var kind: int = inventory.pop_front()
			shoot_cd = 0.20
			arena.fire(self, kind)
			squash = Vector2(0.88, 1.08)
		charge = 0
	if pressed & 8: arena.detonate(pid)
	if pressed & 16 and inventory.size() > 1: inventory.append(inventory.pop_front())
	var falling_speed := velocity.y
	correct_corners(dt)
	move_and_slide()
	if is_on_floor() and not was_grounded and falling_speed > 150:
		squash = Vector2(1.2, 0.8)
		arena.effect(position + Vector2(0, 13), Color("b7bfa6"), "land")
	was_grounded = is_on_floor()
	var old_x := position.x
	position.x = wrapf(position.x, -12, 972)
	if old_x != position.x: trail.clear()
	if position.y > 612:
		position.y = -12
		trail.clear()
	elif position.y < -12:
		position.y = 612
		trail.clear()
	queue_redraw()

# Small corner forgiveness inspired by markolainen's CC0 controller.
# This Godot 4 implementation tests both the sideways route and the forward
# sweep so that correction cannot teleport through a wall or sealed ceiling.
func correct_corners(dt: float) -> void:
	var forward := Vector2.ZERO
	var sideways := Vector2.ZERO
	var limit := 4
	if dash > 0 and absf(velocity.x) > absf(velocity.y) * 2:
		forward = Vector2(velocity.x * dt, 0)
		sideways = Vector2.UP
		limit = 6
	elif velocity.y < 0:
		forward = Vector2(0, velocity.y * dt)
		sideways = Vector2.RIGHT
	else: return
	if not test_move(global_transform, forward): return
	for distance in range(1, limit + 1):
		for sign_value in [1, -1]:
			var offset: Vector2 = sideways * distance * sign_value
			if test_move(global_transform, offset): continue
			var shifted := global_transform
			shifted.origin += offset
			if test_move(shifted, forward): continue
			global_position += offset
			return

func begin_death() -> void:
	death_age = 0
	charge = 0
	trail.clear()
	var local := arena.multiplayer.multiplayer_peer is OfflineMultiplayerPeer or pid == arena.multiplayer.get_unique_id()
	if local:
		var device: int = arena.Gamepad.device_for(Array(Input.get_connected_joypads()), arena.local_two, pid == -1)
		if device >= 0: Input.start_joy_vibration(device, 0.55, 0.85, 0.22)

func _draw() -> void:
	if arena == null: return
	if not alive:
		if death_age < 0.8:
			var t := death_age
			var offset := Vector2(facing * t * 45, -100 * t + 160 * t * t)
			draw_set_transform(offset, facing * t * 5, Vector2(1.1, 0.8))
			draw_texture_rect(arena.art.sprite(skin, false, 0), Rect2(-16, -43, 32, 56), false, Color(1, 1, 1, 1.0 - t / 0.8))
			draw_set_transform(Vector2.ZERO)
			if t < 0.12: draw_circle(Vector2.ZERO, 18, Color(1, 0.95, 0.8, (1 - t / 0.12) * 0.65))
		return
	var art = arena.art
	var moving := absf(velocity.x) > 20
	var texture: Texture2D = art.sprite(skin, moving, anim_time)
	for ghost in trail:
		draw_texture_rect(texture, Rect2(ghost.p - position + Vector2(-16, -42), Vector2(32, 56)), false, Color(tint, ghost.life * 1.8))
	draw_set_transform(visual_offset)
	draw_set_transform(visual_offset + Vector2(0, 13), 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, 0.27))
	draw_set_transform(visual_offset)
	var alpha := 0.5 if invulnerable > 0 and int(invulnerable * 15) % 2 == 0 else 1.0
	draw_set_transform(visual_offset + Vector2(0, 13), 0, Vector2(facing, 1) * squash)
	draw_texture_rect(texture, Rect2(-16, -56, 32, 56), false, Color(1, 1, 1, alpha))
	draw_set_transform(visual_offset)
	var bow_pos := aim * (13 - charge * 4)
	draw_set_transform(visual_offset + bow_pos, aim.angle())
	draw_texture_rect(art.tex("weapon_bow"), Rect2(-7, -13, 14, 26), false, Color(1, 1, 1, alpha))
	draw_set_transform(visual_offset)
	if charge > 0:
		for i in 5:
			draw_circle(aim * (28 + i * 9), 1, Color(tint, 0.6 - i * 0.08))
		draw_line(aim * 10, aim * 26, Color("fff1c4"), 2)
	if dash > 0: draw_arc(Vector2.ZERO, 22, 0, TAU, 20, Color(tint, 0.7), 2)
	# Always identify competitors by both color and player number.
	# Quiver is the only persistent interface above an archer.
	for i in inventory.size():
		var x := -inventory.size() * 4.5 + i * 9 + 4
		var kind: int = inventory[i]
		var color := Color("fff0b5") if kind == 0 else (Color("c8a0fa") if kind == 1 else Color("ffb55c"))
		if kind == 2:
			draw_circle(Vector2(x, -30), 3, color)
			draw_line(Vector2(x, -33), Vector2(x + 2, -36), color, 1)
			draw_rect(Rect2(x - 1, -31, 2, 2), Color("52372a"))
		else:
			draw_line(Vector2(x, -34), Vector2(x, -26), color, 2)
			if kind == 1:
				draw_colored_polygon(PackedVector2Array([Vector2(x - 3, -31), Vector2(x, -36), Vector2(x + 3, -31)]), color)
			else:
				draw_line(Vector2(x, -35), Vector2(x + 2, -32), color, 1)
		if i == 0: draw_line(Vector2(x - 3, -23), Vector2(x + 3, -23), tint, 1)
	draw_set_transform(Vector2.ZERO)

func collect_arrow(kind: int) -> void:
	if inventory.size() < 6: inventory.append(clampi(kind, 0, 2))

func collect_special(kind: int) -> void:
	for i in 2:
		if inventory.size() >= 6: inventory.pop_back()
		inventory.push_front(clampi(kind, 1, 2))
