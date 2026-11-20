class_name Quantity
extends RefCounted
## Số lượng hàng hóa: số nguyên × 1000 theo đơn vị của hàng hóa (t, kg, bbl...).

const SCALE: int = 1000


static func from_units(units: int) -> int:
	return units * SCALE


static func from_float(value: float) -> int:
	return int(roundf(value * SCALE))


static func to_float(qty: int) -> float:
	return float(qty) / float(SCALE)


static func format(qty: int, unit: String = "t") -> String:
	var whole: int = qty / SCALE
	var frac: int = absi(qty % SCALE) / 100
	var text: String = Money.group_thousands(whole)
	if frac != 0 and absi(whole) < 10_000:
		text += ".%d" % frac
	return "%s %s" % [text, unit]
