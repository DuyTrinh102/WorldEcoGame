class_name UnitPrice
extends RefCounted
## Đơn giá (tiền / 1 đơn vị hàng hóa): số nguyên × 10 000 (4 chữ số lẻ).

const SCALE: int = 10_000
## UnitPrice(×1e4) × Quantity(×1e3) = tiền × 1e7; đổi sang cent (×1e2) => chia 1e5.
const _TO_CENTS_DIVISOR: int = 100_000


static func from_float(value: float) -> int:
	return int(roundf(value * SCALE))


static func to_float(price: int) -> float:
	return float(price) / float(SCALE)


## Thành tiền (cent) = đơn giá × số lượng, làm tròn.
static func total(price: int, qty: int) -> int:
	return IntMath.mul_div(price, qty, _TO_CENTS_DIVISOR)


## Đơn giá bình quân = tổng tiền / số lượng.
static func from_total(cents: int, qty: int) -> int:
	if qty == 0:
		return 0
	return IntMath.mul_div(cents, _TO_CENTS_DIVISOR, qty)


static func format(price: int) -> String:
	return Money.format(IntMath.div_round(price, SCALE / Money.SCALE))
