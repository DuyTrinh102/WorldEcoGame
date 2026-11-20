class_name IntMath
extends RefCounted
## Phép toán số nguyên có làm tròn (round half away from zero) và hạn chế tràn số.


## round(a / b)
static func div_round(a: int, b: int) -> int:
	assert(b != 0, "IntMath.div_round: chia cho 0")
	var negative: bool = (a < 0) != (b < 0)
	var aa: int = absi(a)
	var bb: int = absi(b)
	var q: int = aa / bb
	var r: int = aa % bb
	if r * 2 >= bb:
		q += 1
	return -q if negative else q


## round(a * b / c) — tách a = hi*c + lo để tránh tràn int64 với số lớn.
static func mul_div(a: int, b: int, c: int) -> int:
	assert(c != 0, "IntMath.mul_div: chia cho 0")
	var negative: bool = ((a < 0) != (b < 0)) != (c < 0)
	var aa: int = absi(a)
	var bb: int = absi(b)
	var cc: int = absi(c)
	var hi: int = aa / cc
	var lo: int = aa % cc
	var result: int = hi * bb + div_round(lo * bb, cc)
	return -result if negative else result


## round(value * ratio) — dùng cho lãi suất, tỷ lệ. Chỉ dùng khi ratio là tham số cân bằng.
static func mul_ratio(value: int, ratio: float) -> int:
	return int(roundf(float(value) * ratio))
