class_name Fmt
extends RefCounted
## Định dạng hiển thị (tiền, số lượng, %, tên quốc gia/hàng hóa, nội dung event).


static func money(cents: int, compact: bool = false) -> String:
	return Money.format(cents, compact)


static func price(value: float) -> String:
	if value >= 1000.0:
		return "$" + Money.group_thousands(int(roundf(value)))
	return "$%.2f" % value


static func unit_price(p: int) -> String:
	return price(UnitPrice.to_float(p))


static func qty(q: int, unit: String = "t") -> String:
	return Quantity.format(q, unit)


static func pct(ratio: float, signed: bool = true) -> String:
	var v: float = ratio * 100.0
	return ("%+.1f%%" % v) if signed else ("%.1f%%" % v)


static func date(day: int) -> String:
	return GameDate.format(day)


static func commodity(id: String) -> String:
	return Loc.t("COMMODITY_" + id.to_upper())


static func country(id: String) -> String:
	return Loc.t("COUNTRY_" + id)


static func facility(id: String) -> String:
	return Loc.t("FACILITY_" + id.to_upper())


static func signed_color(value: float) -> Color:
	if value > 0.0:
		return AppTheme.GOOD
	if value < 0.0:
		return AppTheme.BAD
	return AppTheme.TEXT


## Định dạng tham số: *_cents -> tiền, qty/*_qty -> số lượng, commodity/country/from/to/facility -> tên.
static func args(data: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k: Variant in data:
		var key: String = str(k)
		var v: Variant = data[k]
		if key.ends_with("_cents"):
			out[key] = money(int(v), true)
		elif key == "qty" or key.ends_with("_qty"):
			out[key] = qty(int(v))
		elif key == "commodity":
			out[key] = commodity(str(v))
		elif key in ["country", "from", "to"]:
			out[key] = country(str(v))
		elif key == "facility":
			out[key] = facility(str(v))
		else:
			out[key] = str(v)
	return out


static func event_text(e: SimEvent) -> String:
	if e.text_key.is_empty():
		return e.type
	return Loc.t(e.text_key, args(e.data))


static func error_text(r: Result) -> String:
	return Loc.t(r.error_key, args(r.args))
