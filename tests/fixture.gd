extends RefCounted
# Stable isolated geometry for controller/combat tests, independent of arena art.
static func install(game: Node) -> void:
	for child in game.terrain.get_children(): child.free()
	game.platforms.assign([Rect2(64, 520, 320, 24), Rect2(576, 520, 320, 24), Rect2(90, 420, 210, 48), Rect2(660, 420, 210, 48), Rect2(350, 320, 260, 72)])
	for rect in game.platforms:
		var body := StaticBody2D.new()
		body.position = rect.get_center()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		body.add_child(shape)
		game.terrain.add_child(body)
