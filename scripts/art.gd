extends RefCounted
var world = preload("res://scripts/arena_world.gd").new()

const SKINS := ["elf_m", "elf_f", "wizzard_f", "knight_m"]
const NAMES := ["Sylva", "Brasa", "Íris", "Corvo"]
const INK := Color("0c131b")
const PAPER := Color("f3e4c9")
const GOLD := Color("e9b969")
var textures: Dictionary = {}
var title_font: Font = preload("res://assets/fonts/Cinzel.ttf")
var body_font: Font = preload("res://assets/fonts/Atkinson.ttf")
var interior: Texture2D = preload("res://assets/gothicvania/old-dark-castle-interior-background.png")
var gothic: Texture2D = preload("res://assets/gothicvania/gothic-castle-background.png")
var town_layers: Array[Texture2D] = []

func _init() -> void:
	for layer in ["sky", "clouds", "mountains", "far-buildings", "town", "forest"]:
		town_layers.append(load("res://assets/gothicvania/night-town-background-" + layer + ".png"))

func tex(key: String) -> Texture2D:
	if not textures.has(key):
		textures[key] = load("res://assets/dungeon/" + key + ".png")
	return textures[key]

func sprite(skin: int, moving: bool, time: float) -> Texture2D:
	var frame := int(time * (11 if moving else 5)) % 4
	return tex(SKINS[posmod(skin, 4)] + ("_run_anim_f" if moving else "_idle_anim_f") + str(frame))

func draw_scenery(c: CanvasItem, index: int, t: float) -> void:
	world.draw(c, index, t)

func draw_platform(c: CanvasItem, rect: Rect2, index: int) -> void:
	var tint := Color("aaa99a") if index == 1 else Color("8eafa8")
	var tiles := ceili(rect.size.x / 32.0)
	for row in ceili(rect.size.y / 32.0):
		for i in tiles:
			var width := minf(32, rect.size.x - i * 32)
			var height := minf(32, rect.size.y - row * 32)
			var key := "wall_mid"
			if i == 0: key = "wall_left"
			elif i == tiles - 1: key = "wall_right"
			c.draw_texture_rect_region(tex(key), Rect2(rect.position + Vector2(i * 32, row * 32), Vector2(width, height)), Rect2(0, 0, width / 2, height / 2), tint.darkened(0.16 if row > 0 else 0.0))
	c.draw_line(rect.position + Vector2(0, 1), Vector2(rect.end.x, rect.position.y + 1), Color("ccb77e") if index == 1 else Color("a6baa1"), 2)
	c.draw_line(Vector2(rect.position.x, rect.end.y + 1), rect.end + Vector2(0, 1), Color("080e17"), 3)

func draw_torch(c: CanvasItem, pos: Vector2, t: float) -> void:
	c.draw_rect(Rect2(pos + Vector2(-3, 0), Vector2(6, 16)), Color("684a35"))
	for layer in range(3, 0, -1):
		c.draw_circle(pos, 10 + layer * 10, Color(1, 0.55, 0.18, 0.014))
	var flame := 9.0 + 2 * sin(t * 13 + pos.x)
	c.draw_colored_polygon(PackedVector2Array([pos + Vector2(-6, 1), pos + Vector2(-3, -flame), pos + Vector2(0, -flame - 4), pos + Vector2(5, -7), pos + Vector2(6, 1)]), Color("e98740"))
	c.draw_rect(Rect2(pos + Vector2(-2, -6), Vector2(4, 8)), Color("ffe0a0"))

func draw_arena(c: CanvasItem, game: Node) -> void:
	var t: float = game.visual_time
	draw_scenery(c, game.map_id, t)
	for pos in [Vector2(96, 100), Vector2(864, 100), Vector2(144, 460), Vector2(816, 460)]:
		draw_torch(c, pos, t)
	for item in game.pickups:
		var color: Color = [Color.WHITE, Color("b89ef6"), Color("ffbc71"), Color("8cddff"), Color("e8e0fb")][item.kind]
		var p: Vector2 = item.p
		c.draw_circle(p, 21 + sin(t * 3) * 2, Color(color, 0.07))
		c.draw_texture_rect(tex("chest_full_open_anim_f0"), Rect2(p - Vector2(16, 14), Vector2(32, 32)), false)
		c.draw_rect(Rect2(p + Vector2(-3, -18 + sin(t * 4) * 2), Vector2(6, 6)), color)
		if item.kind == 3:
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -27), p + Vector2(6, -27), p + Vector2(4, -20), p + Vector2(0, -16), p + Vector2(-4, -20)]), color)
		elif item.kind == 4:
			for side in [-1, 1]: c.draw_line(p + Vector2(0, -20), p + Vector2(side * 10, -28), color, 4)
	for a in game.projectiles:
		var direction: Vector2 = a.v.normalized()
		var color := PAPER
		if a.kind == 1: color = Color("c8a0fa")
		elif a.kind == 2: color = Color("ffb55c")
		if not a.stuck:
			c.draw_line(a.p - direction * 34, a.p - direction * 12, Color(color, 0.24), 2)
		c.draw_set_transform(a.p, direction.angle() + PI / 2)
		c.draw_texture_rect(tex("weapon_arrow"), Rect2(-3, -10, 7, 21), false, color)
		c.draw_set_transform(Vector2.ZERO)
		if a.kind == 2:
			c.draw_circle(a.p, 3, Color(1, 0.65, 0.3, 0.65 + 0.35 * sin(t * 12)))
	for event in game.particle_events:
		var progress: float = 1.0 - event.life / event.get("duration", 0.55)
		var color: Color = event.c
		var amount := 12 if event.key in ["hit", "blast", "catch"] else 5
		for i in amount:
			var direction := Vector2.RIGHT.rotated(i * TAU / amount + event.seq)
			var distance := progress * (54 if amount == 12 else 18)
			var point: Vector2 = event.p + direction * distance + Vector2(0, progress * progress * 26)
			c.draw_rect(Rect2(point.round(), Vector2(3, 3)), Color(color, 1.0 - progress))
		if event.key == "catch": c.draw_arc(event.p, 12 + progress * 34, 0, TAU, 24, Color(color, 1.0 - progress), 2)
		if event.key == "blast": c.draw_arc(event.p, 76 * minf(1, progress * 3), 0, TAU, 32, Color(color, 1.0 - progress), 3)
		var label: String = event.get("text", "")
		if not label.is_empty():
			c.draw_string(body_font, event.p + Vector2(-35, -32 - progress * 22), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(color, 1.0 - progress))
	if game.round_time > 40:
		var inset := minf(480, (game.round_time - 40) * 12)
		c.draw_rect(Rect2(0, 0, inset, 600), Color(0.35, 0.12, 0.32, 0.8))
		c.draw_rect(Rect2(960 - inset, 0, inset, 600), Color(0.35, 0.12, 0.32, 0.8))
		for i in 8:
			var y := 64 + i * 64 + sin(t * 2 + i) * 14
			c.draw_circle(Vector2(inset, y), 14, Color(0.48, 0.19, 0.43, 0.3))
			c.draw_circle(Vector2(960 - inset, y), 14, Color(0.48, 0.19, 0.43, 0.3))
