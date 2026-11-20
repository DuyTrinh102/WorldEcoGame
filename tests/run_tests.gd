extends SceneTree
## Trình chạy test headless:
##   godot --headless --path . -s res://tests/run_tests.gd [-- --filter=market]
## Thoát với mã 1 nếu có test thất bại.

const TEST_DIRS: Array[String] = ["res://tests/unit", "res://tests/scenario"]


func _init() -> void:
	var filter: String = ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.substr(9)
	var files: Array[String] = []
	for dir in TEST_DIRS:
		_collect(dir, files)
	files.sort()
	var total: int = 0
	var failed: int = 0
	var assertions: int = 0
	var started: int = Time.get_ticks_msec()
	for path in files:
		if not filter.is_empty() and not path.contains(filter):
			continue
		var script: GDScript = load(path)
		if script == null:
			printerr("Không nạp được ", path)
			failed += 1
			continue
		for m: Dictionary in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			var tc: TestCase = script.new()
			tc.current_test = "%s::%s" % [path.get_file(), name]
			var t0: int = Time.get_ticks_msec()
			tc.before_each()
			tc.call(name)
			tc.after_each()
			total += 1
			assertions += tc.assertions
			var ms: int = Time.get_ticks_msec() - t0
			if tc.failures.is_empty():
				print("  PASS  %s (%d ms)" % [tc.current_test, ms])
			else:
				failed += 1
				print("  FAIL  %s" % tc.current_test)
				for f in tc.failures:
					print("        - ", f)
	print("\n%d tests, %d failed, %d assertions (%.1fs)" % [total, failed, assertions, (Time.get_ticks_msec() - started) / 1000.0])
	quit(1 if failed > 0 or total == 0 else 0)


func _collect(dir: String, out: Array[String]) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		if f.begins_with("test_") and f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(d), out)
