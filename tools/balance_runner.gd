extends SceneTree
## Chạy mô phỏng headless nhiều năm (không có người chơi) để cân bằng kinh tế.
##   godot --headless --path . -s res://tools/balance_runner.gd -- --years=10 --seed=42 [--csv=user://balance.csv] [--commodity=wheat]
## In tóm tắt theo năm: giá thế giới/giá tham chiếu, tồn kho toàn cầu (ngày cung ứng).


func _init() -> void:
	var years: int = 10
	var seed_value: int = 42
	var csv_path: String = ""
	var only: String = ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--years="): years = arg.substr(8).to_int()
		elif arg.begins_with("--seed="): seed_value = arg.substr(7).to_int()
		elif arg.begins_with("--csv="): csv_path = arg.substr(6)
		elif arg.begins_with("--commodity="): only = arg.substr(12)
	var loader := ContentLoader.new()
	var content: ContentRegistry = loader.load_roots(ContentLoader.DEFAULT_ROOTS)
	if not loader.errors.is_empty():
		printerr(loader.errors)
		quit(1)
		return
	var sim := Simulation.create_from_content(content)
	sim.new_game("default", seed_value)
	var csv: FileAccess = null
	if not csv_path.is_empty():
		csv = FileAccess.open(csv_path, FileAccess.WRITE)
		var header: PackedStringArray = ["day"]
		for kid in content.commodity_ids:
			header.append(kid + "_world")
			for cid in content.country_ids:
				header.append("%s_%s" % [kid, cid])
		csv.store_line(",".join(header))
	var ids: Array[String] = content.commodity_ids.duplicate()
	if not only.is_empty():
		ids = [only]
	_print_year(sim, 0, ids)
	for y in years:
		for d in 365:
			sim.step()
			if csv != null and d % 7 == 0:
				var row: PackedStringArray = [str(sim.world.day)]
				for kid in content.commodity_ids:
					row.append("%.2f" % MarketQueries.world_price(sim.world, kid))
					for cid in content.country_ids:
						row.append("%.2f" % MarketQueries.price(sim.world, cid, kid))
				csv.store_line(",".join(row))
		_print_year(sim, y + 1, ids)
	if csv != null:
		csv.close()
		print("CSV: ", ProjectSettings.globalize_path(csv_path))
	quit(0)


func _print_year(sim: Simulation, year: int, ids: Array[String]) -> void:
	var line: String = "Y%-2d" % year
	var st: MarketState = MarketState.of(sim.world)
	for kid in ids:
		var ref: float = sim.content.commodity(kid).base_price
		var stock: float = 0.0
		var scale: float = 0.0
		var lo: float = INF
		var hi: float = 0.0
		for cid in sim.content.country_ids:
			var e: Dictionary = st.markets[cid][kid]
			stock += float(e["stock"])
			scale += float(e["base_prod"])
			lo = minf(lo, float(e["price"]) / ref)
			hi = maxf(hi, float(e["price"]) / ref)
		line += " | %s %.2f [%.2f-%.2f] %dd" % [kid.substr(0, 6), MarketQueries.world_price(sim.world, kid) / ref, lo, hi, int(stock / (scale / 365.0))]
	print(line)
