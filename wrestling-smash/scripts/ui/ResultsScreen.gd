## VS results: winner banner, per-player column with place, KOs, falls, self-destructs,
## damage dealt / taken (+ points in time mode, stocks left in stock mode).
## normalize() accepts many shapes of the battle's results dictionary (missing keys -> "-"),
## falls back to the engine's gSCManagerBattleState, and ranks like mnvsresults.c when no
## places are given (stock: engine place; time: KOs - falls, ties share a place).
extends "res://scripts/ui/ScreenBase.gd"

const Roster := preload("res://scripts/ui/Roster.gd")
const PK_NOT := 2

var data: Dictionary = {}

func build() -> void:
	data = normalize(args.get("results", {}), args.get("config", {}))
	add_header("RESULTS", ("SIMULATED (NO BATTLE SCENE)   ·   " if data.simulated else "") + app.rules_summary())
	var head := UiTheme.make_label(data.headline, "TitleLabel", 58, data.headline_color)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.position = Vector2(0, 88)
	head.size = Vector2(DESIGN.x, 80)
	canvas.add_child(head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.position = Vector2(40, 176)
	row.size = Vector2(DESIGN.x - 80, 440)
	canvas.add_child(row)
	for pl in data.players:
		row.add_child(_column(pl))
	if data.players.is_empty():
		row.add_child(UiTheme.make_label("No player data was reported by the battle.", "BoldLabel", 20))
	var bb := HBoxContainer.new()
	bb.add_theme_constant_override("separation", 20)
	bb.position = Vector2(DESIGN.x * 0.5 - 380, 636)
	canvas.add_child(bb)
	var cont := make_button("CONTINUE  ▶", func() -> void: app.goto("css"), 300)
	bb.add_child(cont)
	bb.add_child(make_button("CHANGE RULES", func() -> void: app.goto("rules"), 220))
	bb.add_child(make_button("TITLE", func() -> void: app.goto("title", {"menu": true}), 160))
	first_focus = cont

func _column(pl: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(278, 440)
	var col: Color = UiTheme.PLAYER_COLORS[pl.port] if pl.pkind == 0 else UiTheme.CPU_COLOR
	if data.is_team:
		col = UiTheme.TEAM_COLORS[posmod(pl.team, 3)]
	var sb := UiTheme.box(UiTheme.PANEL, UiTheme.GOLD if pl.place == 0 and not data.no_contest else col, 3 if pl.place == 0 else 2, 10, 0.0, 14.0)
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var tag := UiTheme.make_label(("P%d" % (pl.port + 1)) if pl.pkind == 0 else ("CPU %d" % (pl.port + 1)), "NameLabel", 26, col)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tag)
	var place_txt := "-" if pl.place < 0 or data.no_contest else UiTheme.ordinal(pl.place)
	var pc := [UiTheme.GOLD, Color("c9d2e3"), Color("d08a4e")]
	top.add_child(UiTheme.make_label(place_txt, "NameLabel", 34, pc[pl.place] if pl.place >= 0 and pl.place < 3 else UiTheme.DIM))
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(246, 150)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var tex := Roster.portrait(Roster.fighter_slug(pl.fkind))
	if tex != null:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(56, 20, 400, 244)
		tr.texture = at
	v.add_child(tr)
	var f := Roster.fighter(pl.fkind)
	var nm := UiTheme.make_label(str(f.get("name", "?")).to_upper(), "NameLabel", 22)
	nm.clip_text = true
	nm.custom_minimum_size = Vector2(246, 0)
	v.add_child(nm)
	v.add_child(UiTheme.make_label("MOVESET: " + str(f.get("ssb64", "?")).to_upper(), "DimLabel", 12, Color(UiTheme.GOLD, 0.8)))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 2)
	v.add_child(g)
	var stats := [["KOs", pl.kos], ["FALLS", pl.falls], ["SELF-DESTRUCTS", pl.sds], ["DAMAGE DEALT", pl.dealt], ["DAMAGE TAKEN", pl.taken]]
	if not data.is_stock:
		stats.append(["POINTS", pl.points if pl.kos >= 0 and pl.falls >= 0 else -1])
	elif pl.stocks_left >= 0:
		stats.append(["STOCKS LEFT", pl.stocks_left])
	for st in stats:
		var k := UiTheme.make_label(st[0], "DimLabel", 14)
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(k)
		var val := "-" if int(st[1]) < 0 and st[0] != "POINTS" else str(int(st[1]))
		if st[0] == "POINTS" and pl.kos < 0:
			val = "-"
		if st[0].begins_with("DAMAGE") and int(st[1]) >= 0:
			val += " %"
		var vl := UiTheme.make_label(val, "BoldLabel", 18)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		g.add_child(vl)
	return p

func on_start(_device: int) -> bool:
	app.goto("css")
	return true

func on_back() -> void:
	app.goto("css")

# ------------------------------------------------------------------ normalisation
static func _pick(d: Dictionary, keys: Array):
	for k in keys:
		if d.has(k) and d[k] != null:
			return d[k]
	return null

static func _num(d: Dictionary, keys: Array) -> int:
	var v = _pick(d, keys)
	if v is Array:
		var sum := 0
		for x in v:
			sum += int(x)
		return sum
	if v is int or v is float or (v is String and v.is_valid_float()):
		return int(v)
	return -1

## Reads the engine's VS battle state (scripts/core/G.gd) without a compile-time dependency.
static func _engine_players() -> Dictionary:
	var out := {}
	var g = load("res://scripts/core/G.gd") if ResourceLoader.exists("res://scripts/core/G.gd") else null
	if g == null:
		return out
	var st = g.get("gSCManagerBattleState")
	if st == null:
		return out
	for i in mini(4, st.players.size()):
		var sp = st.players[i]
		if int(sp.pkind) == PK_NOT:
			continue
		out[i] = {"pkind": sp.pkind, "fkind": sp.fkind, "team": sp.team, "place": sp.place, "kos": sp.score, "falls": sp.falls,
			"self_destructs": sp.total_selfdestructs, "damage_dealt": sp.total_damage_given, "damage_taken": sp.total_damage_all,
			"stocks_left": sp.stock_count, "_engine": true}
	return out

static func normalize(raw, cfg: Dictionary) -> Dictionary:
	var r: Dictionary = raw if raw is Dictionary else {}
	var out := {"players": [], "simulated": bool(r.get("simulated", false)),
		"is_team": bool(r.get("is_team_battle", cfg.get("is_team_battle", false))),
		"is_stock": bool(r.get("is_stock", cfg.get("is_stock", true))),
		"no_contest": false, "headline": "MATCH OVER", "headline_color": UiTheme.GOLD}
	var rule = _pick(r, ["kind_name", "game_rules", "rule", "rules"])
	if rule is String:
		out.is_stock = not rule.to_lower().contains("time")
	out.no_contest = bool(_pick(r, ["no_contest", "is_no_contest", "is_reset"]) if _pick(r, ["no_contest", "is_no_contest", "is_reset"]) != null else false) \
		or str(r.get("reason", "")).to_lower() in ["quit", "no_contest", "reset"]
	var rps = _pick(r, ["players", "player_results", "results", "ports", "fighters"])
	var by_port := {}
	if rps is Dictionary:
		for k in rps:
			if rps[k] is Dictionary and str(k).is_valid_int():
				by_port[int(k)] = rps[k]
	elif rps is Array:
		for i in rps.size():
			if rps[i] is Dictionary:
				var port = _pick(rps[i], ["port", "player", "index", "slot", "player_index"])
				by_port[int(port) if port != null else i] = rps[i]
	if by_port.is_empty():
		by_port = _engine_players()
	var cps: Array = cfg.get("players", [])
	var place_key := ""
	for i in 4:
		var c: Dictionary = cps[i] if i < cps.size() and cps[i] is Dictionary else {}
		var p: Dictionary = by_port.get(i, {})
		if p.has("present") and not bool(p.present):
			continue
		var pk_v = _pick(p, ["pkind", "player_kind"])
		var pkind := int(pk_v) if pk_v != null else int(c.get("pkind", PK_NOT))
		if pkind == PK_NOT or (p.is_empty() and c.is_empty()):
			continue
		var fk = _pick(p, ["fkind", "fighter_kind", "fighter"])
		var tm = _pick(p, ["team"])
		var e := {"port": i, "pkind": pkind, "fkind": int(fk) if (fk is int or fk is float) else int(c.get("fkind", 0)),
			"team": int(tm) if tm != null else int(c.get("team", i)),
			"kos": _num(p, ["kos", "ko", "ko_count", "total_kos", "score", "total_kos_players"]),
			"falls": _num(p, ["falls", "tko", "tkos", "deaths", "times_ko"]),
			"sds": _num(p, ["self_destructs", "sds", "sd", "total_selfdestructs", "selfdestructs"]),
			"dealt": _num(p, ["damage_dealt", "damage_given", "total_damage_given", "dmg_dealt"]),
			"taken": _num(p, ["damage_taken", "total_damage_all", "damage_received", "dmg_taken"]),
			"stocks_left": _num(p, ["stocks_left", "stock_count", "stocks_remaining"]),
			"place": -1}
		for k in ["place", "placement", "rank", "position"]:
			if p.has(k) and p[k] != null:
				e.place = int(p[k])
				place_key = k
				break
		if p.get("_engine", false) and not out.is_stock:
			e.place = -1   # SSB64 time places come from points, not the engine field
		e["points"] = (e.kos - e.falls) if e.kos >= 0 and e.falls >= 0 else 0
		out.players.append(e)
	# places given 1-based ("placement": 1 = winner)?
	var known: Array = out.players.filter(func(e) -> bool: return e.place >= 0)
	if not known.is_empty() and place_key != "place":
		var mn := 99
		for e in known:
			mn = mini(mn, e.place)
		if mn >= 1:
			for e in out.players:
				if e.place >= 1:
					e.place -= 1
	if known.size() < out.players.size():
		_rank(out)
	out["win_player"] = int(r.win_player) if (r.get("win_player") is int or r.get("win_player") is float) else -1
	_headline(out)
	return out

## Places from points (time) or stocks left (stock), shared on ties; teams ranked by total.
static func _rank(out: Dictionary) -> void:
	var score := func(e: Dictionary) -> int:
		if out.is_stock and e.stocks_left >= 0:
			return e.stocks_left * 1000 + e.points
		return e.points
	var groups := {}
	for e in out.players:
		var key = e.team if out.is_team else e.port
		groups[key] = int(groups.get(key, 0)) + int(score.call(e))
	var vals := groups.values()
	vals.sort()
	vals.reverse()
	for e in out.players:
		var key = e.team if out.is_team else e.port
		var sc: int = groups[key]
		var place := 0
		var seen := {}
		for v in vals:
			if v > sc and not seen.has(v):
				seen[v] = true
				place += 1
		if e.place < 0:
			e.place = place

static func _headline(out: Dictionary) -> void:
	if out.no_contest:
		out.headline = "NO CONTEST"
		out.headline_color = UiTheme.DIM
		return
	var winners: Array = out.players.filter(func(e) -> bool: return e.place == 0)
	for e in out.players:
		if e.port == out.get("win_player", -1):
			winners = [e]   # engine's mnVSResultsGetWinPlayer() (tie breaks / sudden death applied)
	if winners.is_empty():
		return
	if out.is_team:
		var t: int = posmod(winners[0].team, 3)
		out.headline = UiTheme.TEAM_NAMES[t] + " TEAM WINS!"
		out.headline_color = UiTheme.TEAM_COLORS[t]
	elif winners.size() == 1:
		out.headline = Roster.fighter_name(winners[0].fkind).to_upper() + " WINS!"
		out.headline_color = UiTheme.GOLD
	else:
		out.headline = "DRAW!"
