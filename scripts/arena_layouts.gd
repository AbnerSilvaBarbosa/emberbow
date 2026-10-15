extends RefCounted
# 24px masonry grid. Empty cells are navigable; outlines and collision share it.
const CELL := 24
const WIDTH := 40
const HEIGHT := 25
static func cells(index: int) -> Dictionary:
	var grid: Dictionary = {}
	var put := func(x: int, y: int, w: int, h: int):
		for yy in range(y, y + h):
			for xx in range(x, x + w): grid[Vector2i(xx, yy)] = true
	var pair := func(x: int, y: int, w: int, h: int):
		put.call(x, y, w, h)
		put.call(WIDTH - x - w, y, w, h)
	# Broken enclosing walls leave a lateral passage and a central vertical shaft.
	pair.call(0, 0, 18, 1)
	pair.call(0, 1, 6, 2)
	pair.call(6, 1, 8, 1)
	pair.call(0, 3, 3, 3)
	pair.call(0, 6, 1, 3)
	pair.call(0, 13, 1, 7)
	pair.call(0, 20, 3, 3)
	pair.call(0, 23, 18, 2)
	pair.call(3, 22, 6, 1)
	match index:
		0, 2:
			# Garden: upper chambers, side niches, stepped bowl, a split obelisk.
			pair.call(5, 2, 3, 2)
			pair.call(3, 5, 5, 1)
			pair.call(7, 5, 2, 2)
			pair.call(0, 7, 8, 1)
			pair.call(5, 11, 4, 2)
			pair.call(1, 17, 3, 1)
			pair.call(3, 19, 3, 1)
			put.call(19, 12, 2, 5)
			put.call(17, 17, 6, 1)
			if index == 2:
				pair.call(11, 8, 3, 1)
				pair.call(12, 20, 3, 2)
			else:
				put.call(19, 6, 2, 1)
				pair.call(11, 20, 5, 1)
		1, 4:
			# Fortress: hooked upper balconies, tall wall-jump faces and low tunnels.
			pair.call(12, 2, 5, 1)
			pair.call(14, 6, 2, 4)
			pair.call(11, 10, 6, 1)
			pair.call(4, 9, 3, 1)
			pair.call(1, 14, 3, 2)
			pair.call(7, 16, 2, 3)
			pair.call(12, 18, 4, 2)
			pair.call(12, 22, 6, 2)
			put.call(19, 3, 2, 3)
			if index == 1:
				put.call(19, 15, 2, 3)
			else:
				put.call(19, 20, 2, 2)
		3, 5:
			# Crypt: central spine with two flanking loops and recessed shelves.
			pair.call(6, 4, 4, 1)
			pair.call(8, 5, 3, 1)
			pair.call(1, 10, 6, 1)
			pair.call(8, 10, 3, 1)
			pair.call(2, 17, 5, 1)
			pair.call(6, 18, 2, 2)
			put.call(19, 2, 2, 2)
			put.call(19, 9, 2, 2)
			put.call(19, 17, 2, 4)
			pair.call(14, 20, 2, 3)
			if index == 5: pair.call(12, 13, 3, 2)
	return grid

static func rectangles(index: int) -> Array[Rect2]:
	var grid := cells(index)
	var result: Array[Rect2] = []
	for y in HEIGHT:
		var x := 0
		while x < WIDTH:
			if not grid.has(Vector2i(x, y)):
				x += 1
				continue
			var start := x
			while x < WIDTH and grid.has(Vector2i(x, y)): x += 1
			result.append(Rect2(start * CELL, y * CELL, (x - start) * CELL, CELL))
	return result

static func spawn_at(index: int, slot: int) -> Vector2:
	var grid := cells(index)
	var targets := [Vector2(160, 320), Vector2(800, 320), Vector2(320, 510), Vector2(640, 510)]
	var target: Vector2 = targets[slot % 4]
	var best := Vector2(480, 100)
	var distance := INF
	for cell: Vector2i in grid:
		if cell.y < 4: continue
		if grid.has(cell + Vector2i.UP) or grid.has(cell + Vector2i(0, -2)): continue
		var point := Vector2(cell) * CELL + Vector2(CELL / 2, -14)
		var d := point.distance_squared_to(target)
		if d < distance:
			distance = d
			best = point
	return best
