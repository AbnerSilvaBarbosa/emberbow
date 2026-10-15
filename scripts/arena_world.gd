extends RefCounted
const Layouts = preload("res://scripts/arena_layouts.gd")
var cached_index := -1
var grid: Dictionary = {}

func draw(c: CanvasItem, index: int, t: float) -> void:
	if cached_index != index:
		cached_index = index
		grid = Layouts.cells(index)
	var garden := index in [0, 2]
	var ember := index == 1
	var edge := Color("a9b971") if garden else (Color("be996d") if ember else Color("8bb9cc"))
	var mid := Color("657b38") if garden else (Color("735844") if ember else Color("285c83"))
	var dark := Color("0a180d") if garden else Color("090e24")
	c.draw_rect(Rect2(0, 0, 960, 600), Color("3989dc") if garden else Color("111528"))
	if garden:
		# Layered pixel clouds and distant mountains, behind the playable masonry.
		for i in 9:
			var x := float(posmod(i * 173, 1100) - 90)
			var y := float(65 + posmod(i * 83, 250))
			for tier in 3:
				c.draw_rect(Rect2(x + tier * 16, y - tier * 8, 130 - tier * 32, 8), Color("69aff0"))
		for layer in 2:
			var points := PackedVector2Array([Vector2(0, 600)])
			for x in range(0, 1001, 24):
				var y := 335 + sin(x * 0.012 + layer) * 60 + sin(x * 0.024) * 23 + layer * 65
				points.append(Vector2(x, floor(y / 8) * 8))
			points.append(Vector2(1000, 600))
			c.draw_colored_polygon(points, Color("548fac") if layer == 0 else Color("37696e"))
		# Snowcaps break the distant silhouettes into short pixel steps.
		for peak in [Vector2(214, 294), Vector2(682, 294)]:
			for step in 5:
				c.draw_rect(Rect2(peak + Vector2(-step * 8, step * 6), Vector2(8 + step * 16, 4)), Color("8abdc9"))
		# A ruined tower in the distance.
		c.draw_rect(Rect2(548, 192, 32, 228), Color("4b8399"))
		c.draw_rect(Rect2(540, 184, 48, 16), Color("4b8399"))
		for x in [540, 560, 580]: c.draw_rect(Rect2(x, 174, 8, 18), Color("4b8399"))
	# Decorative rear walls have no bright outline: navigable space stays legible.
	for y in 25:
		for x in 40:
			var seed := posmod(x * 71 + y * 137, 101)
			var rear := y > 12 + int(3 * sin(x * 0.18)) or (y < 7 and (x < 11 or x > 28))
			if not garden: rear = x < 9 or x > 30 or (x > 13 and x < 26 and y < 8) or y > 21
			if not rear: continue
			var p := Vector2(x * 24, y * 24)
			var base := Color("2d5734") if garden else Color("292e49")
			c.draw_rect(Rect2(p, Vector2(24, 24)), base)
			if seed < 40: c.draw_rect(Rect2(p + Vector2(3, 3), Vector2(18, 18)), base.lightened(0.035 + seed * 0.001))
			if seed % 11 == 0:
				for j in 4:
					c.draw_rect(Rect2(p + Vector2(4 + j * 4, 5 + (j % 2) * 4), Vector2(3, 3)), Color("608457") if garden else Color("465676"))
			if garden and seed % 13 == 0:
				c.draw_rect(Rect2(p + Vector2(7, 11), Vector2(3, 10)), Color("176346"))
				c.draw_rect(Rect2(p + Vector2(10, 8), Vector2(5, 4)), Color("248763"))
	if not garden:
		# Recessed archways and a cold pool of distant light.
		for x in [230, 610]:
			c.draw_rect(Rect2(x, 170, 120, 340), Color("0c0d20"))
			c.draw_rect(Rect2(x + 20, 148, 80, 30), Color("0c0d20"))
			for side in [x - 12, x + 120]:
				c.draw_rect(Rect2(side, 180, 12, 310), Color("343950"))
				for yy in range(180, 480, 24): c.draw_rect(Rect2(side, yy, 12, 3), Color("47516a"))
		for i in 18:
			var inset := absf(sin(i * 0.7)) * 70
			c.draw_rect(Rect2(214 + inset, 466 + i * 7, 532 - inset * 2, 4), Color("557f97").darkened(i * 0.025))
	# Faded stone carvings and climbing foliage live on the rear wall.
	for side in [96, 824]:
		for yy in [338, 434, 522]:
			var motif := Color("507a4c") if garden else Color("414c69")
			for step in 4:
				var half := 3 + step * 3
				c.draw_line(Vector2(side - half, yy + step * 3), Vector2(side, yy - half), motif, 2)
				c.draw_line(Vector2(side + half, yy + step * 3), Vector2(side, yy - half), motif, 2)
			c.draw_rect(Rect2(side - 2, yy + 11, 4, 5), motif)
	if garden:
		for i in 22:
			var xx := posmod(i * 139 + 67, 880) + 40
			var yy := posmod(i * 73, 175) + 360
			for leaf in 4:
				c.draw_rect(Rect2(xx + (leaf % 2) * 5, yy + leaf * 4, 7, 3), Color("187055"))
			if i % 3 == 0:
				c.draw_rect(Rect2(xx + 1, yy - 3, 4, 5), Color("67bbe2"))
				c.draw_rect(Rect2(xx - 2, yy, 10, 3), Color("4593c7"))
	# Chains hang in open space; their weight is visually distinct from stone.
	for x in [264, 360, 600, 696]:
		for y in range(24, 176 + posmod(x, 3) * 24, 10):
			c.draw_rect(Rect2(x, y, 4, 8), mid.darkened(0.12), false, 1)
		c.draw_rect(Rect2(x - 3, 174, 10, 6), mid)
	for cell: Vector2i in grid:
		var p := Vector2(cell) * 24
		var seed := posmod(cell.x * 37 + cell.y * 71, 29)
		c.draw_rect(Rect2(p, Vector2(24, 24)), dark)
		# Sparse mineral flecks rather than stretching a rectangular texture.
		if seed < 12:
			c.draw_rect(Rect2(p + Vector2(4 + seed % 9, 7), Vector2(7, 3)), mid.darkened(0.57))
			c.draw_rect(Rect2(p + Vector2(12, 15), Vector2(4, 3)), mid.darkened(0.65))
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if grid.has(cell + direction): continue
			var r: Rect2
			if direction == Vector2i.UP: r = Rect2(p, Vector2(24, 10))
			elif direction == Vector2i.DOWN: r = Rect2(p + Vector2(0, 14), Vector2(24, 10))
			elif direction == Vector2i.LEFT: r = Rect2(p, Vector2(10, 24))
			else: r = Rect2(p + Vector2(14, 0), Vector2(10, 24))
			c.draw_rect(r, mid)
			c.draw_rect(Rect2(r.position + Vector2(2, 2), r.size - Vector2(4, 4)), edge.darkened(0.16 + seed % 4 * 0.035))
			c.draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(3, 3)), mid.darkened(0.16))
			c.draw_line(r.position, r.position + Vector2(r.size.x, 0), edge, 2)
			c.draw_line(r.position, r.position + Vector2(0, r.size.y), edge, 2)
			if direction == Vector2i.UP:
				c.draw_rect(Rect2(p + Vector2(3, -2), Vector2(7, 3)), edge)
				if not garden and not ember:
					c.draw_rect(Rect2(p + Vector2(1, -3), Vector2(21, 4)), Color("d0dfdf"))
					c.draw_rect(Rect2(p + Vector2(17, 1), Vector2(3, 5)), Color("9bc8de"))
			elif direction == Vector2i.DOWN and seed % 3 == 0:
				c.draw_rect(Rect2(p + Vector2(7, 24), Vector2(3, 7)), mid)
	# Pixel embers / snow, subdued enough to keep projectile contrast.
	for i in 28:
		var p := Vector2(posmod(i * 137, 960), fposmod(i * 73 + t * (6 if garden else 13), 600)).floor()
		c.draw_rect(Rect2(p, Vector2(2, 2)), Color(edge, 0.25))
