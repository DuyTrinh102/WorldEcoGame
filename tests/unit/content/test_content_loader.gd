extends TestCase


func test_base_data_loads_without_errors() -> void:
	var loader := ContentLoader.new()
	var reg: ContentRegistry = loader.load_roots(ContentLoader.DEFAULT_ROOTS)
	assert_eq(loader.errors.size(), 0, str(loader.errors))
	assert_eq(reg.country_ids.size(), 8)
	assert_eq(reg.commodity_ids.size(), 12)
	assert_true(reg.facility_ids.size() >= 4)
	assert_true(reg.scenarios.has("default"))


func test_settings_path_lookup() -> void:
	var reg: ContentRegistry = TestWorld.content()
	assert_near(reg.setting_f("market.target_cover_days"), 90.0, 0.001)
	assert_eq(reg.setting("does.not.exist", "x"), "x")


func test_validator_detects_bad_reference() -> void:
	var reg: ContentRegistry = TestWorld.content()
	var f := FacilityDef.new()
	f.id = "broken"
	f.output = "unobtainium"
	f.inputs = {"coffee": 1.0}
	var copy := ContentRegistry.new()
	copy.commodities = reg.commodities
	copy.countries = reg.countries
	copy.accounts = reg.accounts
	copy.scenarios = reg.scenarios
	copy.facilities = {"broken": f}
	copy.finalize()
	var errs: Array[String] = ContentValidator.validate(copy)
	assert_true(errs.any(func(e: String) -> bool: return e.contains("unobtainium")), str(errs))


func test_deep_merge_patch() -> void:
	var merged: Dictionary = ContentLoader._deep_merge({"a": 1, "m": {"x": 1, "y": 2}}, {"$patch": true, "m": {"y": 5}})
	assert_eq(merged, {"a": 1, "m": {"x": 1, "y": 5}})
