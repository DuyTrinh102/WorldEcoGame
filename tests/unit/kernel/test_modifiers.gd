extends TestCase


func _mod(target: String, stat: String, op: Modifier.Op, value: float, start: int = 0, end: int = -1) -> Modifier:
	var m := Modifier.new()
	m.target = target
	m.stat = stat
	m.op = op
	m.value = value
	m.start_day = start
	m.end_day = end
	m.source = "test"
	return m


func test_add_then_multiply() -> void:
	var s := ModifierStack.new()
	s.add(_mod("country:VNM", "market.production", Modifier.Op.MULTIPLY, 0.5))
	s.add(_mod("commodity:coffee", "market.production", Modifier.Op.ADD, 10.0))
	s.add(_mod("country:BRA", "market.production", Modifier.Op.MULTIPLY, 0.1))
	var targets: Array[String] = ["country:VNM", "commodity:coffee"]
	assert_near(s.resolve(targets, "market.production", 100.0, 5), 55.0, 1e-6)


func test_inactive_and_expired() -> void:
	var s := ModifierStack.new()
	s.add(_mod("country:VNM", "x", Modifier.Op.MULTIPLY, 2.0, 10, 20))
	var t: Array[String] = ["country:VNM"]
	assert_near(s.resolve(t, "x", 1.0, 5), 1.0, 1e-6)
	assert_near(s.resolve(t, "x", 1.0, 15), 2.0, 1e-6)
	s.remove_expired(21)
	assert_eq(s.all().size(), 0)


func test_serialization_roundtrip() -> void:
	var s := ModifierStack.new()
	s.add(_mod("country:VNM", "x", Modifier.Op.ADD, 3.0, 1, 9))
	var copy := ModifierStack.new()
	copy.from_array(JSON.parse_string(JSON.stringify(s.to_array())))
	assert_eq(copy.all()[0].to_dict(), s.all()[0].to_dict())
