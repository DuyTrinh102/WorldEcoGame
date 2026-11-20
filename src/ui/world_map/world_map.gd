class_name WorldMap
extends Control
## Bản đồ thế giới: lục địa giản lược, cảng/quốc gia, tài sản của người chơi, tuyến tàu đang chạy.
## Bộ lọc hàng hóa tô màu quốc gia theo giá so với giá thế giới (xanh = rẻ, đỏ = đắt).

signal country_selected(country_id: String)

const LAT_TOP: float = 78.0
const LAT_BOTTOM: float = -58.0
const MARKER_RADIUS: float = 11.0

var main: MainUI
var selected: String = ""
var filter_commodity: String = ""
var _hover: String = ""
var _land: Array[PackedVector2Array] = []
var _land_ok: Array[bool] = []
var _filter: OptionButton
var _legend: Label


func setup(p_main: MainUI) -> void:
	main = p_main
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	for poly in MapData.polygons():
		_land.append(poly)
		_land_ok.append(not Geometry2D.triangulate_polygon(poly).is_empty())
	var bar := UI.hbox(8)
	bar.position = Vector2(14, 12)
	bar.add_child(UI.label(Loc.t("MAP_FILTER"), "MutedLabel"))
	_filter = OptionButton.new()
	_filter.focus_mode = Control.FOCUS_NONE
	_filter.add_item(Loc.t("MAP_FILTER_NONE"))
	_filter.set_item_metadata(0, "")
	for kid in main.session.content.commodity_ids:
		_filter.add_item(Fmt.commodity(kid))
		_filter.set_item_metadata(_filter.item_count - 1, kid)
	_filter.item_selected.connect(func(i: int) -> void:
		filter_commodity = str(_filter.get_item_metadata(i))
		_legend.visible = not filter_commodity.is_empty()
		queue_redraw())
	bar.add_child(_filter)
	_legend = UI.label(Loc.t("MAP_LEGEND"), "MutedLabel")
	_legend.visible = false
	bar.add_child(_legend)
	add_child(bar)


func refresh() -> void:
	queue_redraw()


# ------------------------------------------------------------------ chiếu bản đồ

func _map_rect() -> Rect2:
	var sx: float = size.x / 360.0
	var sy: float = clampf(size.y / (LAT_TOP - LAT_BOTTOM), sx * 0.9, sx * 1.5)
	var h: float = sy * (LAT_TOP - LAT_BOTTOM)
	return Rect2(0, (size.y - h) / 2.0 + 10.0, size.x, h)


func project(lon: float, lat: float) -> Vector2:
	var r: Rect2 = _map_rect()
	return Vector2(r.position.x + (lon + 180.0) / 360.0 * r.size.x, r.position.y + (LAT_TOP - lat) / (LAT_TOP - LAT_BOTTOM) * r.size.y)


func _country_pos(id: String) -> Vector2:
	var c: CountryDef = main.session.content.country(id)
	return project(c.lon, c.lat)


# ------------------------------------------------------------------ vẽ

func _draw() -> void:
	if main == null or not main.session.is_ready():
		return
	var font: Font = get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), AppTheme.OCEAN, true)
	var r: Rect2 = _map_rect()
	for lon in range(-180, 181, 30):
		var x: float = project(lon, 0).x
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), AppTheme.OCEAN_GRID, 1.0)
	for lat in range(-45, 76, 15):
		var y: float = project(0, lat).y
		draw_line(Vector2(0, y), Vector2(size.x, y), AppTheme.OCEAN_GRID, 1.0)
	for i in _land.size():
		var pts := PackedVector2Array()
		for p in _land[i]:
			pts.append(project(p.x, p.y))
		if _land_ok[i]:
			draw_colored_polygon(pts, AppTheme.LAND)
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, AppTheme.LAND_EDGE, 1.0, true)
	_draw_shipments()
	_draw_countries(font)
	if not _hover.is_empty():
		_draw_tooltip(font, _hover)


func _draw_shipments() -> void:
	var w: WorldState = main.session.world()
	for s in LogisticsQueries.shipments_of(w, main.session.company_id()):
		var a: Vector2 = _country_pos(str(s["from_country"]))
		var b: Vector2 = _country_pos(str(s["to_country"]))
		var t: float = LogisticsQueries.progress(w, s)
		var color: Color = main.session.content.commodity(str(s["commodity"])).color.lightened(0.25)
		# Đi đường ngắn hơn qua đường đổi ngày nếu cần.
		var dx: float = b.x - a.x
		var width: float = _map_rect().size.x
		if absf(dx) > width / 2.0:
			var b2: Vector2 = b - Vector2(signf(dx) * width, 0)
			_draw_arc(a, b2, color, t)
			_draw_arc(a + Vector2(signf(dx) * width, 0), b, color, t)
		else:
			_draw_arc(a, b, color, t)


func _arc_points(a: Vector2, b: Vector2) -> PackedVector2Array:
	var mid: Vector2 = (a + b) / 2.0
	var normal: Vector2 = (b - a).orthogonal().normalized()
	var ctrl: Vector2 = mid + normal * (a.distance_to(b) * 0.18) * (1.0 if a.x < b.x else -1.0)
	var pts := PackedVector2Array()
	for i in 25:
		var t: float = i / 24.0
		pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	return pts


func _draw_arc(a: Vector2, b: Vector2, color: Color, progress: float, with_dot: bool = true) -> void:
	var pts: PackedVector2Array = _arc_points(a, b)
	for i in range(0, pts.size() - 1, 2):
		draw_line(pts[i], pts[i + 1], Color(color, 0.7), 2.0, true)
	if with_dot:
		var idx: float = progress * (pts.size() - 1)
		var p: Vector2 = pts[int(floor(idx))].lerp(pts[mini(int(floor(idx)) + 1, pts.size() - 1)], idx - floor(idx))
		draw_circle(p, 5.0, AppTheme.ACCENT)
		draw_circle(p, 2.5, AppTheme.BG)


func _draw_countries(font: Font) -> void:
	var w: WorldState = main.session.world()
	var co: String = main.session.company_id()
	for cid in main.session.content.country_ids:
		var c: CountryDef = main.session.content.country(cid)
		var p: Vector2 = _country_pos(cid)
		var fill: Color = AppTheme.PANEL_3
		var caption: String = Fmt.country(cid)
		if not filter_commodity.is_empty():
			var price: float = MarketQueries.price(w, cid, filter_commodity)
			var ratio: float = price / maxf(MarketQueries.world_price(w, filter_commodity), 0.01)
			fill = _ratio_color(ratio)
			caption += "  " + Fmt.price(price)
		if cid == selected:
			draw_circle(p, MARKER_RADIUS + 7.0, Color(AppTheme.ACCENT, 0.25))
			draw_arc(p, MARKER_RADIUS + 7.0, 0, TAU, 32, AppTheme.ACCENT, 2.0, true)
		draw_circle(p, MARKER_RADIUS, fill)
		draw_arc(p, MARKER_RADIUS, 0, TAU, 32, c.color, 3.0, true)
		var has_wh: bool = not InventoryQueries.warehouse_in(w, co, cid).is_empty()
		var factories: int = ProductionQueries.factories_in(w, co, cid).size()
		if has_wh:
			draw_rect(Rect2(p + Vector2(-5, -5), Vector2(10, 10)), AppTheme.ACCENT, true)
		var label_pos: Vector2 = p + Vector2(MARKER_RADIUS + 6, 5)
		draw_string_outline(font, label_pos, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, AppTheme.OCEAN)
		draw_string(font, label_pos, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, AppTheme.TEXT if cid != selected else AppTheme.ACCENT)
		for i in factories:
			var fp: Vector2 = p + Vector2(-MARKER_RADIUS - 4 - i * 11, -MARKER_RADIUS - 6)
			draw_colored_polygon(PackedVector2Array([fp + Vector2(0, -7), fp + Vector2(5, 3), fp + Vector2(-5, 3)]), AppTheme.GOOD)


func _ratio_color(ratio: float) -> Color:
	var t: float = clampf((ratio - 1.0) / 0.15, -1.0, 1.0)
	if t < 0.0:
		return AppTheme.PANEL_3.lerp(AppTheme.GOOD, -t)
	return AppTheme.PANEL_3.lerp(AppTheme.BAD, t)


func _draw_tooltip(font: Font, cid: String) -> void:
	var w: WorldState = main.session.world()
	var c: CountryDef = main.session.content.country(cid)
	var lines: Array[String] = [
		Fmt.country(cid),
		Loc.t("MAP_TIP_PORT", {"port": c.port_name}),
		Loc.t("MAP_TIP_POP", {"pop": "%.1f" % (c.population / 1_000_000.0)}),
		Loc.t("MAP_TIP_GDP", {"gdp": Money.group_thousands(int(c.gdp_per_capita))}),
	]
	if not filter_commodity.is_empty():
		lines.append("%s: %s" % [Fmt.commodity(filter_commodity), Fmt.price(MarketQueries.price(w, cid, filter_commodity))])
	lines.append(Loc.t("MAP_TIP_CLICK"))
	var p: Vector2 = _country_pos(cid) + Vector2(16, 14)
	var box := Rect2(p, Vector2(220, 18 * lines.size() + 12))
	if box.end.x > size.x:
		box.position.x -= box.size.x + 32
	if box.end.y > size.y:
		box.position.y -= box.size.y + 28
	draw_rect(box, Color(AppTheme.PANEL_2, 0.95), true)
	draw_rect(box, AppTheme.BORDER, false, 1.0)
	for i in lines.size():
		draw_string(font, box.position + Vector2(10, 20 + i * 18), lines[i], HORIZONTAL_ALIGNMENT_LEFT, 200, 13 if i > 0 else 14, AppTheme.ACCENT if i == 0 else AppTheme.TEXT)


# ------------------------------------------------------------------ input

func _country_at(pos: Vector2) -> String:
	var best: String = ""
	var best_d: float = MARKER_RADIUS + 10.0
	for cid in main.session.content.country_ids:
		var d: float = _country_pos(cid).distance_to(pos)
		if d < best_d:
			best_d = d
			best = cid
	return best


func _gui_input(event: InputEvent) -> void:
	if main == null or not main.session.is_ready():
		return
	if event is InputEventMouseMotion:
		var h: String = _country_at((event as InputEventMouseMotion).position)
		if h != _hover:
			_hover = h
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not h.is_empty() else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var cid: String = _country_at(mb.position)
			if not cid.is_empty():
				selected = cid
				country_selected.emit(cid)
				queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and not _hover.is_empty():
		_hover = ""
		queue_redraw()
	elif what == NOTIFICATION_RESIZED:
		queue_redraw()
