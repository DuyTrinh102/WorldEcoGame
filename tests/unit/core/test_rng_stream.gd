extends TestCase


func test_same_inputs_same_sequence() -> void:
	var a := RngStream.create(7, "market.coffee", 100)
	var b := RngStream.create(7, "market.coffee", 100)
	for i in 5:
		assert_eq(a.randi(), b.randi())


func test_different_streams_differ() -> void:
	var a := RngStream.create(7, "market.coffee", 100)
	var b := RngStream.create(7, "market.rice", 100)
	assert_ne(a.randi(), b.randi())
