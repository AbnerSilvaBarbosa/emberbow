extends CanvasLayer

var game: Node
var root: Control
var overlay: Control
var home: Control
var online: Control
var lobby: Control
var help: Control
var paused: Control
var results: Control
var pages: Dictionary = {}
var current_page := "home"
var preview: Control
var preview_title: Label
var preview_description: Label
var skin_buttons: Array[Button] = []
var portrait: TextureRect
var skin_name: Label
var lobby_roster: Label
var result_roster: Label
var result_title: Label
var start_button: Button
var rematch_button: Button
var health: Control
var footer: Label
var countdown: Label
var round_hint: Label
var previous_mode := "menu"
var music_button: Button
var last_status := ""

const GOLD := Color("e9b969")
const TEXT := Color("f3e4c9")
const MUTED := Color("aab8b8")
const BG := Color("111e26")
const DESCRIPTIONS := ["Pedra antiga. Ângulos fechados.\nDomine a plataforma central.", "Plataformas em escada. Combate vertical.\nGanhe altura e pressione o adversário.", "Sob a lua, ninguém fica escondido.\nMude de lado e surpreenda pelo alto.", "Ilhas pequenas sobre um grande vazio.\nCaia e volte ao topo para surpreender.", "Duas torres, muitas rotas.\nSuba pelas paredes ou atravesse a tela.", "O centro é aberto, a disputa é vertical.\nControle as bordas e ataque de cima."]

func build(owner_game: Node) -> void:
	game = owner_game
	layer = 10
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = make_theme()
	add_child(root)
	health = Control.new()
	health.size = Vector2(960, 600)
	health.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health.draw.connect(draw_hud)
	root.add_child(health)
	footer = label(root, "", Vector2(24, 566), 14, MUTED)
	countdown = label(root, "", Vector2(220, 230), 64, TEXT, true)
	countdown.size = Vector2(520, 80)
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_hint = label(root, "", Vector2(190, 318), 20, TEXT)
	round_hint.size = Vector2(580, 44)
	round_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.banner = countdown
	game.hud = footer
	overlay = Control.new()
	overlay.size = Vector2(960, 600)
	root.add_child(overlay)
	overlay.draw.connect(func():
		overlay.draw_rect(Rect2(0, 0, 960, 600), Color(0.025, 0.045, 0.065, 0.86))
		overlay.draw_line(Vector2(56, 65), Vector2(904, 65), Color("42504b"))
		overlay.draw_line(Vector2(56, 542), Vector2(904, 542), Color("42504b")))
	game.menu = overlay
	label(overlay, "EMBERBOW", Vector2(56, 26), 18, GOLD, true)
	label(overlay, "UM ARCO. UMA CHANCE.", Vector2(655, 28), 14, MUTED)
	game.status = label(overlay, "", Vector2(56, 505), 16, GOLD)
	game.status.size = Vector2(850, 34)
	game.status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	music_button = button(overlay, "Música: ligada", Rect2(746, 548, 158, 30), toggle_music, false)
	var credits := button(overlay, "Controles e créditos", Rect2(56, 548, 205, 30), func(): show_page("help"), false)
	credits.add_theme_font_size_override("font_size", 14)
	for page_name in ["home", "online", "lobby", "help", "paused", "results"]:
		var page := Control.new()
		page.size = Vector2(960, 480)
		page.position.y = 76
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(page)
		pages[page_name] = page
	home = pages.home
	online = pages.online
	lobby = pages.lobby
	help = pages.help
	paused = pages.paused
	results = pages.results
	build_home()
	build_online()
	build_lobby()
	build_help()
	build_pause()
	build_results()
	show_page("home")

func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = game.art.body_font
	theme.default_font_size = 18
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = BG
		style.border_color = Color("58665c")
		style.set_border_width_all(1)
		style.content_margin_left = 16
		style.content_margin_right = 16
		if state == "hover":
			style.bg_color = Color("243631")
			style.border_color = GOLD
		if state == "pressed": style.bg_color = Color("394435")
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = Color("ffe4ac")
			style.set_border_width_all(2)
		if state == "disabled": style.bg_color = Color("141f26")
		theme.set_stylebox(state, "Button", style)
		theme.set_color("font_" + state + "_color" if state != "normal" else "font_color", "Button", MUTED if state == "disabled" else TEXT)
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color("0b141d")
	input_style.border_color = Color("6c7c73")
	input_style.set_border_width_all(1)
	input_style.content_margin_left = 14
	input_style.content_margin_right = 14
	theme.set_stylebox("normal", "LineEdit", input_style)
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	return theme

func label(parent: Node, text: String, pos: Vector2, font_size: int, color := TEXT, display := false) -> Label:
	var node := Label.new()
	node.text = text
	node.position = pos
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	if display: node.add_theme_font_override("font", game.art.title_font)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func button(parent: Node, text: String, rect: Rect2, callback: Callable, primary := false) -> Button:
	var node := Button.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	if primary:
		for state in ["normal", "hover", "pressed"]:
			var style := StyleBoxFlat.new()
			style.bg_color = GOLD.lightened(0.1) if state == "hover" else GOLD
			if state == "pressed": style.bg_color = GOLD.darkened(0.15)
			style.content_margin_left = 16
			node.add_theme_stylebox_override(state, style)
			node.add_theme_color_override("font_" + state + "_color" if state != "normal" else "font_color", Color("1c261f"))
	if primary:
		node.add_theme_color_override("font_focus_color", Color("1c261f"))
	node.pressed.connect(func():
		game.sound("ui")
		callback.call())
	parent.add_child(node)
	return node

func build_home() -> void:
	label(home, "Emberbow", Vector2(56, 4), 48, TEXT, true)
	label(home, "Flechas voam. Reflexos decidem.", Vector2(59, 71), 20, MUTED)
	label(home, "Escolha seu arqueiro", Vector2(59, 117), 16, MUTED)
	for i in 4:
		var b := button(home, "", Rect2(58 + i * 76, 148, 66, 70), func(): select_skin(i))
		var image := TextureRect.new()
		image.texture = game.art.sprite(i, false, 0)
		image.position = Vector2(17, 0)
		image.size = Vector2(32, 56)
		image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(image)
		skin_buttons.append(b)
	skin_name = label(home, "", Vector2(59, 223), 15, GOLD)
	select_skin(game.selected_skin)
	button(home, "Treinar contra bot", Rect2(58, 265, 324, 48), func(): game.practice(false), true)
	button(home, "Duelo no mesmo computador", Rect2(58, 324, 324, 44), func(): game.practice(true))
	button(home, "Jogar online", Rect2(58, 379, 324, 44), func(): show_page("online"))
	preview_title = label(home, "", Vector2(474, 26), 24, GOLD, true)
	preview = Control.new()
	preview.position = Vector2(474, 80)
	preview.size = Vector2(430, 248)
	preview.clip_contents = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home.add_child(preview)
	preview.draw.connect(draw_preview)
	button(home, "<", Rect2(474, 346, 40, 38), func(): change_map(-1))
	button(home, ">", Rect2(864, 346, 40, 38), func(): change_map(1))
	label(home, "Primeiro a 10 eliminações", Vector2(534, 351), 19, TEXT)
	preview_description = label(home, "", Vector2(474, 397), 16, MUTED)
	game.map_select = OptionButton.new()
	for map_name in game.MAPS: game.map_select.add_item(map_name)
	game.map_select.hide()
	home.add_child(game.map_select)
	change_map(0)

func select_skin(index: int) -> void:
	game.selected_skin = index
	if is_instance_valid(skin_name): skin_name.text = game.art.NAMES[index] + "  ·  Mesmas habilidades, seu estilo"
	for i in skin_buttons.size():
		var style := StyleBoxFlat.new()
		style.bg_color = Color("24352f") if i == index else Color("111e26")
		style.border_color = GOLD if i == index else Color("40534d")
		style.set_border_width_all(2 if i == index else 1)
		skin_buttons[i].add_theme_stylebox_override("normal", style)

func change_map(direction: int) -> void:
	var index := posmod(game.map_select.selected + direction, game.MAPS.size())
	game.map_select.select(index)
	if game.mode == "menu": game.build_map(index)
	preview_title.text = game.MAPS[index]
	preview_description.text = DESCRIPTIONS[index % DESCRIPTIONS.size()]
	preview.queue_redraw()

func draw_preview() -> void:
	preview.draw_set_transform(Vector2(0, -26), 0, Vector2(0.448, 0.5))
	game.art.draw_scenery(preview, game.map_select.selected, game.visual_time)
	game.art.draw_torch(preview, Vector2(480, 218), game.visual_time)
	for i in 2:
		preview.draw_texture_rect(game.art.sprite(i, true, game.visual_time), Rect2(150 + i * 580, 487, 32, 56), false)
	preview.draw_set_transform(Vector2.ZERO)
	preview.draw_rect(Rect2(0, 0, 430, 248), Color("63796b"), false, 1)

func build_online() -> void:
	label(online, "Reúna os arqueiros", Vector2(56, 20), 34, TEXT, true)
	label(online, "Crie uma sala ou entre na partida de um amigo.", Vector2(58, 75), 19, MUTED)
	label(online, "Criar uma sala", Vector2(58, 145), 24, GOLD)
	label(online, "Você escolhe a arena e inicia a partida.\nAté quatro jogadores por sala.", Vector2(58, 188), 18, TEXT)
	button(online, "Criar sala", Rect2(58, 271, 332, 48), func():
		game.host()
		if game.mode == "lobby": show_page("lobby"), true)
	label(online, "Entrar em uma sala", Vector2(504, 145), 24, GOLD)
	game.address = LineEdit.new()
	game.address.position = Vector2(504, 193)
	game.address.size = Vector2(398, 48)
	game.address.placeholder_text = "IP do anfitrião"
	game.address.text = "127.0.0.1"
	game.address.max_length = 253
	online.add_child(game.address)
	game.address.text_submitted.connect(func(_value): connect_to_host())
	button(online, "Conectar", Rect2(504, 271, 398, 48), connect_to_host)
	label(online, "Na mesma rede, use o IP local. Pela internet, o anfitrião precisa\nliberar a porta UDP 24680 ou usar uma VPN com os amigos.", Vector2(58, 332), 17, MUTED)
	button(online, "Voltar", Rect2(58, 388, 120, 34), func(): show_page("home"))

func connect_to_host() -> void:
	game.join()
	if game.mode == "connecting": show_page("lobby")

func build_lobby() -> void:
	label(lobby, "Prepare sua sala", Vector2(56, 20), 34, TEXT, true)
	label(lobby, "A partida começa quando o anfitrião estiver pronto.", Vector2(58, 76), 19, MUTED)
	lobby_roster = label(lobby, "", Vector2(58, 142), 23, TEXT)
	lobby_roster.size = Vector2(820, 160)
	start_button = button(lobby, "Iniciar partida", Rect2(58, 337, 332, 48), func(): game.start_match(), true)
	button(lobby, "Copiar IP local", Rect2(420, 337, 210, 48), func():
		var ips := IP.get_local_addresses()
		var chosen := "127.0.0.1"
		for ip in ips:
			if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
				chosen = ip
				break
		DisplayServer.clipboard_set(chosen)
		game.status.text = "IP copiado: " + chosen + " · para jogadores na mesma rede.")
	button(lobby, "Sair da sala", Rect2(58, 388, 160, 34), func(): game.leave("Você saiu da sala."))

func build_help() -> void:
	label(help, "Domine o arco", Vector2(56, 10), 34, TEXT, true)
	label(help, "Um acerto elimina. Capture a flecha com o dash ou vença com um pisão.", Vector2(58, 64), 19, MUTED)
	label(help, "TECLADO / JOGADOR 1", Vector2(58, 116), 17, GOLD)
	label(help, "WASD       Mover e mirar\nEspaço      Pular (segure para ir mais alto)\nJ / Mouse  Segure para mirar, solte para atirar\nK / Direito Dash e captura\nL / R         Detonar / trocar flecha", Vector2(58, 154), 18, TEXT)
	label(help, "JOGADOR 2 / CONTROLE", Vector2(514, 116), 17, GOLD)
	label(help, "Setas        Mover e mirar\nEnter        Pular\nShift         Segurar e soltar o tiro\nCtrl           Dash e captura\nBackspace Detonar  ·  . trocar flecha", Vector2(514, 154), 18, TEXT)
	label(help, "Controle: analógico/D-pad move · direito mira · A pula · X/RT atira\nB/LB dash: toque curto / segure longo · Y detona · RB troca · Start pausa.", Vector2(58, 307), 17, MUTED)
	label(help, "Local: 1 controle = P2; 2 controles = P1 e P2. Teclado continua disponível.", Vector2(58, 357), 15, MUTED)
	button(help, "Voltar ao jogo" if game.mode == "playing" else "Voltar", Rect2(58, 388, 180, 34), func():
		if game.mode == "playing": show_page("paused")
		else: show_page("home"))

func build_pause() -> void:
	label(paused, "Respire. Mire. Volte.", Vector2(56, 38), 34, TEXT, true)
	label(paused, "No modo online, a partida continua enquanto este menu está aberto.", Vector2(58, 96), 18, MUTED)
	button(paused, "Continuar partida", Rect2(58, 162, 350, 48), resume, true)
	button(paused, "Ver controles", Rect2(58, 226, 350, 44), func(): show_page("help"))
	var shake := CheckButton.new()
	shake.text = "Trepidação de impacto"
	shake.position = Vector2(58, 295)
	shake.button_pressed = game.screen_shake
	shake.toggled.connect(func(value): game.screen_shake = value)
	paused.add_child(shake)
	button(paused, "Sair para o menu", Rect2(58, 359, 350, 44), func(): game.leave(""))
	label(paused, "Esc  continuar   ·   M  música   ·   F11  tela cheia", Vector2(58, 405), 16, MUTED)

func build_results() -> void:
	result_title = label(results, "Vitória!", Vector2(56, 27), 42, GOLD, true)
	label(results, "A arena já espera o próximo duelo.", Vector2(58, 88), 19, MUTED)
	result_roster = label(results, "", Vector2(58, 157), 25, TEXT)
	rematch_button = button(results, "Jogar novamente", Rect2(58, 326, 330, 48), func(): game.start_match(), true)
	button(results, "Voltar ao menu", Rect2(58, 388, 210, 36), func(): game.leave(""))

func show_page(page_name: String) -> void:
	current_page = page_name
	overlay.show()
	for key in pages: pages[key].visible = key == page_name
	if page_name == "online": game.status.text = ""
	var buttons: Array = pages[page_name].find_children("*", "Button", false, false)
	if not buttons.is_empty(): buttons[0].grab_focus()

func resume() -> void:
	game.notice = ""
	overlay.hide()

func toggle_music() -> void:
	game.music_on = not game.music_on
	if game.music_on: game.music.play()
	else: game.music.stop()

func _process(_dt: float) -> void:
	if not is_instance_valid(game): return
	music_button.text = "Música: " + ("ligada" if game.music_on else "desligada")
	var active: bool = game.mode == "playing"
	health.visible = active and not overlay.visible and game.next_round > 0
	footer.visible = false
	countdown.visible = false
	round_hint.visible = false
	footer.text = "WASD mover   ESPAÇO pular   J atirar   K capturar   L detonar   R trocar" + ("   |   P2: setas / Enter / Shift / Ctrl" if game.local_two else "   |   ESC menu")
	health.queue_redraw()
	if home.visible: preview.queue_redraw()
	if game.mode == "finished" and previous_mode != "finished": show_page("results")
	if game.mode == "lobby" and previous_mode == "playing": show_page("lobby")
	previous_mode = game.mode
	start_button.disabled = not game.multiplayer.is_server() or game.players.size() < 2
	rematch_button.disabled = not game.multiplayer.is_server()
	if lobby.visible:
		var lines := PackedStringArray()
		for p in game.players.values():
			lines.append("P%d   %s%s" % [p.slot + 1, game.art.NAMES[p.skin], "  ·  você" if p.pid == game.multiplayer.get_unique_id() else "  ·  conectado"])
		for i in range(game.players.size(), 4): lines.append("P%d   Aguardando arqueiro…" % (i + 1))
		lobby_roster.text = "\n".join(lines)
	if results.visible:
		var lines := PackedStringArray()
		var sorted_players: Array = game.players.values()
		sorted_players.sort_custom(func(a, b): return a.score > b.score)
		for p in sorted_players: lines.append("P%d  %s     %d %s" % [p.slot + 1, game.art.NAMES[p.skin], p.score, "eliminação" if p.score == 1 else "eliminações"])
		result_roster.text = "\n".join(lines)
		if game.players.has(game.winner): result_title.text = game.art.NAMES[game.players[game.winner].skin] + " venceu!"
	countdown.text = ""
	round_hint.text = ""
	if active and game.next_round > 0:
		if game.round_time == 0:
			countdown.text = str(ceili(game.next_round))
			round_hint.text = "Prepare o arco"
		else:
			countdown.text = "Rodada encerrada"
			countdown.add_theme_font_size_override("font_size", 34)
			round_hint.text = "Recolha o fôlego. O duelo continua."
	else: countdown.add_theme_font_size_override("font_size", 64)
	if active and game.round_time > 40:
		round_hint.text = "A névoa está fechando a arena"
		round_hint.position.y = 90
	else: round_hint.position.y = 318

func centered(text: String, y: float, size: int, color: Color, font: Font = null) -> void:
	if font == null: font = game.art.title_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	health.draw_string(font, Vector2((960 - width) / 2, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func draw_hud() -> void:
	if game.next_round <= 0: return
	if game.round_time == 0:
		var progress := clampf(game.next_round / 2.4, 0, 1)
		var shutter := 70.0 * progress * progress
		health.draw_rect(Rect2(0, 0, 960, shutter), Color("080f19"))
		health.draw_rect(Rect2(0, 600 - shutter, 960, shutter), Color("080f19"))
		health.draw_rect(Rect2(300, 225, 360, 145), Color(0.02, 0.04, 0.08, 0.78))
		centered("RODADA %d" % game.round_number, 258, 23, GOLD)
		centered(str(ceili(game.next_round)), 327, 62, TEXT)
		return
	if game.next_round > game.SCORE_TIME:
		draw_replay()
		return
	var entrance := clampf((3.4 - game.next_round) * 4, 0, 1)
	health.draw_rect(Rect2(0, 0, 960, 600), Color(0.02, 0.03, 0.07, 0.73 * entrance))
	centered("RODADA ENCERRADA", 130, 34, TEXT)
	var roster: Array = game.players.values()
	roster.sort_custom(func(a, b): return a.slot < b.slot)
	var start_y := 232.0 - maxf(0, roster.size() - 2) * 15
	var elapsed: float = game.SCORE_TIME - game.next_round
	for i in roster.size():
		var p: Node = roster[i]
		var y := start_y + i * 70
		var delta: int = p.score - p.round_start_score
		var steps := clampi(int(maxf(0, elapsed - 0.4) / 0.22), 0, absi(delta))
		var shown: int = p.round_start_score + steps * signi(delta)
		health.draw_texture_rect(game.art.sprite(p.skin, false, game.visual_time), Rect2(172, y - 44, 40, 70), false)
		health.draw_string(game.art.body_font, Vector2(226, y - 2), "P%d · %s" % [p.slot + 1, game.art.NAMES[p.skin]], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, p.tint)
		for point in 10:
			var pos := Vector2(395 + point * 29, y - 10)
			var filled := point < shown
			var changed := point >= mini(p.score, p.round_start_score) and point < maxi(p.score, p.round_start_score)
			var color := GOLD if filled else Color("39454d")
			if changed and elapsed < 0.4: color = TEXT
			health.draw_circle(pos + Vector2(0, 2), 10, Color("131a24"))
			health.draw_circle(pos, 9, color)
			health.draw_arc(pos, 6, 0, TAU, 12, Color("fff0ac") if filled else Color("65717a"), 1)
			if filled: health.draw_line(pos + Vector2(0, -4), pos + Vector2(0, 4), Color("967035"), 2)
		var change := "+%d" % delta if delta > 0 else str(delta)
		health.draw_string(game.art.body_font, Vector2(703, y - 2), "%d/10  (%s)" % [shown, change], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, p.tint)
	centered("PRÓXIMA RODADA" if game.winner == 0 else "PARTIDA ENCERRADA", 470, 18, GOLD)
	health.draw_rect(Rect2(340, 491, 280 * clampf(game.next_round / 3.4, 0, 1), 3), GOLD)

func draw_replay() -> void:
	var elapsed: float = game.replay_elapsed()
	if elapsed < game.DEATH_HOLD:
		health.draw_rect(Rect2(0, 0, 960, 600), Color(0.01, 0.02, 0.05, 0.5 * elapsed / game.DEATH_HOLD))
		return
	var rewinding: bool = elapsed < game.DEATH_HOLD + game.REWIND_TIME
	var frame: Dictionary = game.replay_frame()
	game.art.draw_scenery(health, game.map_id, game.visual_time)
	if not frame.is_empty():
		for p in frame.actors:
			if not p.alive:
				var t: float = clampf(elapsed - game.DEATH_HOLD - game.REWIND_TIME - 2.7, 0, 0.8)
				health.draw_set_transform(p.p + Vector2(p.facing * t * 45, -100 * t + 160 * t * t), p.facing * t * 5)
				health.draw_texture_rect(game.art.sprite(p.skin, false, 0), Rect2(-16, -43, 32, 56), false, Color(1, 1, 1, 1 - t / 0.8))
				health.draw_set_transform(Vector2.ZERO)
				continue
			if p.get("shield", false): health.draw_arc(p.p, 24, 0, TAU, 24, Color(0.45, 0.85, 1, 0.75), 2)
			if p.get("wings", false):
				for side in [-1, 1]:
					health.draw_colored_polygon(PackedVector2Array([p.p + Vector2(side * 8, -4), p.p + Vector2(side * 27, -19), p.p + Vector2(side * 22, 3)]), Color("e8e0fb"))
			health.draw_set_transform(p.p, 0, Vector2(p.facing, 1))
			health.draw_texture_rect(game.art.sprite(p.skin, absf(p.v.x) > 20, frame.time), Rect2(-16, -43, 32, 56), false)
			health.draw_set_transform(Vector2.ZERO)
			health.draw_line(p.p + p.aim * 9, p.p + p.aim * 23, p.tint, 3)
		for arrow in frame.arrows:
			var color := TEXT if arrow.kind == 0 else (Color("c8a0fa") if arrow.kind == 1 else GOLD)
			health.draw_line(arrow.p - arrow.v.normalized() * 12, arrow.p, color, 3)
		for effect in frame.effects:
			if effect.key == "hit": health.draw_arc(effect.p, 24, 0, TAU, 16, effect.c, 3)
	health.draw_rect(Rect2(0, 0, 960, 42), Color(0.02, 0.03, 0.06, 0.85))
	health.draw_rect(Rect2(0, 42, 960, 558), Color(0.02, 0.03, 0.1, 0.28 if rewinding else 0.12))
	if rewinding:
		for y in range(46, 600, 12):
			health.draw_rect(Rect2(0, y + int(elapsed * 55) % 12, 960, 2), Color(0.65, 0.8, 1, 0.12))
	centered("REBOBINANDO" if rewinding else "REPLAY · CÂMERA LENTA", 29, 19, GOLD)
