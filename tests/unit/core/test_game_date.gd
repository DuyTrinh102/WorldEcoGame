extends TestCase


func test_ymd_roundtrip() -> void:
	for ymd: Vector3i in [Vector3i(1970, 1, 1), Vector3i(2000, 2, 29), Vector3i(2027, 12, 31), Vector3i(2100, 3, 1)]:
		var ord: int = GameDate.from_ymd(ymd.x, ymd.y, ymd.z)
		assert_eq(GameDate.to_ymd(ord), ymd)


func test_epoch_is_zero() -> void:
	assert_eq(GameDate.from_ymd(1970, 1, 1), 0)


func test_month_end_and_leap_year() -> void:
	assert_true(GameDate.is_month_end(GameDate.from_ymd(2028, 2, 29)))
	assert_false(GameDate.is_month_end(GameDate.from_ymd(2027, 2, 27)))
	assert_true(GameDate.is_month_end(GameDate.from_ymd(2027, 2, 28)))
	assert_eq(GameDate.days_in_month(2100, 2), 28)


func test_week_end_is_sunday() -> void:
	# 2027-01-03 là Chủ nhật
	assert_true(GameDate.is_week_end(GameDate.from_ymd(2027, 1, 3)))
	assert_false(GameDate.is_week_end(GameDate.from_ymd(2027, 1, 4)))


func test_format_and_parse() -> void:
	var d: int = GameDate.parse("2027-03-15")
	assert_eq(GameDate.format(d), "15/03/2027")
	assert_eq(GameDate.period_key(d), "2027-03")
