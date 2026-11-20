class_name TestCase
extends RefCounted
## Lớp cơ sở cho test. Mỗi hàm bắt đầu bằng "test_" là một test case.
## Framework tối giản, không phụ thuộc addon (xem docs/DECISIONS.md ADR-010).

var failures: Array[String] = []
var assertions: int = 0
var current_test: String = ""


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func fail(message: String) -> void:
	failures.append("%s: %s" % [current_test, message])


func assert_true(condition: bool, message: String = "") -> void:
	assertions += 1
	if not condition:
		fail("expected true. " + message)


func assert_false(condition: bool, message: String = "") -> void:
	assertions += 1
	if condition:
		fail("expected false. " + message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	assertions += 1
	if typeof(actual) != typeof(expected) or actual != expected:
		fail("expected <%s> (%s) but got <%s> (%s). %s" % [expected, type_string(typeof(expected)), actual, type_string(typeof(actual)), message])


func assert_ne(actual: Variant, expected: Variant, message: String = "") -> void:
	assertions += 1
	if typeof(actual) == typeof(expected) and actual == expected:
		fail("expected value != <%s>. %s" % [expected, message])


func assert_near(actual: float, expected: float, tolerance: float, message: String = "") -> void:
	assertions += 1
	if absf(actual - expected) > tolerance:
		fail("expected %f ± %f but got %f. %s" % [expected, tolerance, actual, message])


func assert_between(actual: float, low: float, high: float, message: String = "") -> void:
	assertions += 1
	if actual < low or actual > high:
		fail("expected %f in [%f, %f]. %s" % [actual, low, high, message])


func assert_ok(result: Result, message: String = "") -> void:
	assertions += 1
	if result == null or not result.ok:
		fail("expected OK but got %s. %s" % [result, message])


func assert_err(result: Result, key: String, message: String = "") -> void:
	assertions += 1
	if result == null or result.ok or result.error_key != key:
		fail("expected error %s but got %s. %s" % [key, result, message])
