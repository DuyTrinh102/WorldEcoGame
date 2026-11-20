class_name LineChart
extends Control
## Biểu đồ đường đơn giản: nhiều chuỗi số, tự co giãn trục Y.

var series: Array[Dictionary] = []   # {values: Array, color: Color, label: String}
var value_formatter: Callable = func(v: float) -> String: return Fmt.price(v)
var zero_line: bool = false


func _init() -> void:
	custom_minimum_size = Vector2(240, 140)


func set_series(data: Array[Dictionary]) -> void:
	series = data
	queue_redraw()


func _draw() -> void:
	var font: Font = get_theme_default_font()
	var r := Rect2(Vector2(54, 8), size - Vector2(62, 30))
	draw_rect(Rect2(Vector2.ZERO, size), AppTheme.BG, true)
	var lo: float = INF
	var hi: float = -INF
	var n: int = 0
	for s in series:
		for v: Variant in s["values"]:
			lo = minf(lo, float(v))
			hi = maxf(hi, float(v))
		n = maxi(n, (s["values"] as Array).size())
	if n < 2:
		draw_string(font, Vector2(12, size.y / 2), Loc.t("CHART_NO_DATA"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, AppTheme.MUTED)
		return
	if zero_line:
		lo = minf(lo, 0.0)
		hi = maxf(hi, 0.0)
	if is_equal_approx(lo, hi):
		hi = lo + maxf(absf(lo) * 0.05, 1.0)
		lo = lo - maxf(absf(lo) * 0.05, 1.0)
	var pad: float = (hi - lo) * 0.08
	lo -= pad
	hi += pad
	for i in 5:
		var y: float = r.position.y + r.size.y * i / 4.0
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), AppTheme.PANEL_3, 1.0)
		var v: float = hi - (hi - lo) * i / 4.0
		draw_string(font, Vector2(2, y + 4), value_formatter.call(v), HORIZONTAL_ALIGNMENT_LEFT, 50, 10, AppTheme.MUTED)
	if zero_line and lo < 0.0 and hi > 0.0:
		var zy: float = r.end.y - (0.0 - lo) / (hi - lo) * r.size.y
		draw_line(Vector2(r.position.x, zy), Vector2(r.end.x, zy), AppTheme.MUTED, 1.0)
	var legend_x: float = r.position.x
	for s in series:
		var values: Array = s["values"]
		var pts := PackedVector2Array()
		for i in values.size():
			var x: float = r.position.x + r.size.x * float(i + (n - values.size())) / float(n - 1)
			var y: float = r.end.y - (float(values[i]) - lo) / (hi - lo) * r.size.y
			pts.append(Vector2(x, y))
		if pts.size() >= 2:
			draw_polyline(pts, s["color"], 2.0, true)
		var lbl: String = str(s.get("label", ""))
		if not lbl.is_empty():
			draw_rect(Rect2(legend_x, size.y - 14, 10, 4), s["color"])
			draw_string(font, Vector2(legend_x + 14, size.y - 8), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, AppTheme.MUTED)
			legend_x += 24 + font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
