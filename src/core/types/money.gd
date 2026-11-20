class_name Money
extends RefCounted
## Tiền tệ hạch toán: số nguyên, đơn vị nhỏ nhất = 1/100 (cent).
## KHÔNG dùng float cho số dư hay bút toán. Prototype hạch toán bằng USD.

const SCALE: int = 100


static func from_units(units: int) -> int:
	return units * SCALE


## Chỉ dùng khi đọc dữ liệu cấu hình hoặc nhập liệu từ UI.
static func from_float(value: float) -> int:
	return int(roundf(value * SCALE))


static func to_float(cents: int) -> float:
	return float(cents) / float(SCALE)


static func format(cents: int, compact: bool = false) -> String:
	var negative: bool = cents < 0
	var abs_cents: int = absi(cents)
	var text: String
	if compact:
		var v: float = float(abs_cents) / float(SCALE)
		if v >= 1_000_000_000.0:
			text = "%.2fB" % (v / 1_000_000_000.0)
		elif v >= 1_000_000.0:
			text = "%.2fM" % (v / 1_000_000.0)
		elif v >= 10_000.0:
			text = "%.1fK" % (v / 1_000.0)
		else:
			text = group_thousands(abs_cents / SCALE)
	else:
		text = "%s.%02d" % [group_thousands(abs_cents / SCALE), abs_cents % SCALE]
	return ("-$" if negative else "$") + text


static func group_thousands(value: int) -> String:
	var s: String = str(absi(value))
	var out: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if value < 0 else "") + out
