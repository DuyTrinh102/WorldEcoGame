class_name GameDate
extends RefCounted
## Ngày mô phỏng biểu diễn bằng một số nguyên (số ngày kể từ 1970-01-01).
## Thuật toán days-from-civil (H. Hinnant) — tất định, không phụ thuộc OS.


static func from_ymd(year: int, month: int, day: int) -> int:
	var y: int = year - (1 if month <= 2 else 0)
	var era: int = (y if y >= 0 else y - 399) / 400
	var yoe: int = y - era * 400
	var mp: int = month + (-3 if month > 2 else 9)
	var doy: int = (153 * mp + 2) / 5 + day - 1
	var doe: int = yoe * 365 + yoe / 4 - yoe / 100 + doy
	return era * 146097 + doe - 719468


## Trả về Vector3i(year, month, day).
static func to_ymd(ordinal: int) -> Vector3i:
	var z: int = ordinal + 719468
	var era: int = (z if z >= 0 else z - 146096) / 146097
	var doe: int = z - era * 146097
	var yoe: int = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
	var y: int = yoe + era * 400
	var doy: int = doe - (365 * yoe + yoe / 4 - yoe / 100)
	var mp: int = (5 * doy + 2) / 153
	var d: int = doy - (153 * mp + 2) / 5 + 1
	var m: int = mp + (3 if mp < 10 else -9)
	return Vector3i(y + (1 if m <= 2 else 0), m, d)


static func parse(text: String) -> int:
	var parts: PackedStringArray = text.split("-")
	assert(parts.size() == 3, "GameDate.parse: cần dạng YYYY-MM-DD")
	return from_ymd(parts[0].to_int(), parts[1].to_int(), parts[2].to_int())


static func is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or year % 400 == 0


static func days_in_month(year: int, month: int) -> int:
	match month:
		2:
			return 29 if is_leap_year(year) else 28
		4, 6, 9, 11:
			return 30
		_:
			return 31


static func is_month_end(ordinal: int) -> bool:
	return to_ymd(ordinal + 1).z == 1


## Chủ nhật = cuối tuần (1970-01-01 là thứ Năm).
static func is_week_end(ordinal: int) -> bool:
	return posmod(ordinal + 4, 7) == 0


static func month(ordinal: int) -> int:
	return to_ymd(ordinal).y


static func period_key(ordinal: int) -> String:
	var v: Vector3i = to_ymd(ordinal)
	return "%04d-%02d" % [v.x, v.y]


static func format(ordinal: int) -> String:
	var v: Vector3i = to_ymd(ordinal)
	return "%02d/%02d/%04d" % [v.z, v.y, v.x]
