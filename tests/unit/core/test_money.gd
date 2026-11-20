extends TestCase


func test_format_money() -> void:
	assert_eq(Money.format(123456789), "$1,234,567.89")
	assert_eq(Money.format(-5), "-$0.05")
	assert_eq(Money.format(Money.from_units(2_500_000), true), "$2.50M")
	assert_eq(Money.format(Money.from_units(15_300), true), "$15.3K")


func test_div_round_half_away_from_zero() -> void:
	assert_eq(IntMath.div_round(5, 2), 3)
	assert_eq(IntMath.div_round(-5, 2), -3)
	assert_eq(IntMath.div_round(4, 3), 1)
	assert_eq(IntMath.div_round(-4, 3), -1)


func test_mul_div_large_values_no_overflow() -> void:
	# 1e15 * 1e6 / 1e6 vượt int64 nếu nhân thẳng.
	var big: int = 1_000_000_000_000_000
	assert_eq(IntMath.mul_div(big, 1_000_000, 1_000_000), big)


func test_unit_price_total() -> void:
	var price: int = UnitPrice.from_float(4200.0)       # $4,200/t
	var qty: int = Quantity.from_units(1000)             # 1,000 t
	assert_eq(UnitPrice.total(price, qty), Money.from_units(4_200_000))
	# 0.5 t × $3.3333 = $1.66665 -> $1.67
	assert_eq(UnitPrice.total(UnitPrice.from_float(3.3333), Quantity.from_float(0.5)), 167)


func test_unit_price_from_total_roundtrip() -> void:
	var qty: int = Quantity.from_units(1190)
	var total: int = Money.from_units(4_998_000)
	assert_eq(UnitPrice.from_total(total, qty), UnitPrice.from_float(4200.0))


func test_quantity_format() -> void:
	assert_eq(Quantity.format(Quantity.from_float(1234.5)), "1,234.5 t")
	assert_eq(Quantity.format(Quantity.from_units(25_000)), "25,000 t")
