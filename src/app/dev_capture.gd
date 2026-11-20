extends Node
## Công cụ dev: chạy kịch bản demo và chụp màn hình từng màn hình rồi thoát.
##   godot --path . -- --no-welcome --capture=/đường/dẫn/prefix [--demo]
## Dùng cho kiểm thử giao diện tự động (CI/screenshot), không ảnh hưởng gameplay.

var main: MainUI
var prefix: String = ""
var demo: bool = false
var soak_seconds: int = 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			prefix = arg.substr(10)
		elif arg == "--demo":
			demo = true
		elif arg.begins_with("--soak="):
			soak_seconds = arg.substr(7).to_int()
	_run.call_deferred()


func _wait(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame


func _run() -> void:
	await _wait(10)
	if demo:
		_play_demo()
	if soak_seconds > 0:
		await _soak()
	var shots: Array[String] = ["map", "market", "warehouses", "factories", "shipments", "finance", "news"]
	for s in shots:
		main.show_screen(s)
		await _wait(8)
		_capture(s)
	if demo:
		main.show_screen("map")
		main.open_trade(false, "DEU", "roasted_coffee")
		await _wait(8)
		_capture("dialog_sell")
		_close_windows()
		await _wait(2)
		main.open_build(InventoryQueries.warehouse_in(main.session.world(), main.session.company_id(), "VNM"))
		await _wait(8)
		_capture("dialog_build")
		_close_windows()
		await _wait(2)
		main.show_welcome()
		await _wait(8)
		_capture("welcome")
	get_tree().quit()


## Chạy thời gian thực ở tốc độ tối đa, vừa chạy vừa chuyển màn hình (kiểm tra lỗi runtime của UI).
func _soak() -> void:
	var start_day: int = main.session.world().day
	main.session.set_speed(4)
	var screens: Array[String] = ["map", "market", "warehouses", "factories", "shipments", "finance", "news"]
	var t0: int = Time.get_ticks_msec()
	var i: int = 0
	while Time.get_ticks_msec() - t0 < soak_seconds * 1000:
		main.show_screen(screens[i % screens.size()])
		i += 1
		await get_tree().create_timer(1.5).timeout
	main.session.set_speed(0)
	print("soak: %d days simulated in %ds" % [main.session.world().day - start_day, soak_seconds])


func _close_windows() -> void:
	for c in main.get_children():
		if c is Window:
			(c as Window).hide()
			c.queue_free()


func _capture(name: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("%s_%s.png" % [prefix, name])
	print("captured ", name)


func _play_demo() -> void:
	var s: Node = main.session
	var co: String = s.company_id()
	var w: WorldState = s.world()
	var vn: String = InventoryQueries.warehouse_in(w, co, "VNM")
	main.submit(TakeLoanCommand.create(co, Money.from_units(3_000_000)))
	main.submit(OpenWarehouseCommand.create(co, "DEU"))
	main.submit(OpenWarehouseCommand.create(co, "CHN"))
	var de: String = InventoryQueries.warehouse_in(w, co, "DEU")
	var cn: String = InventoryQueries.warehouse_in(w, co, "CHN")
	main.submit(BuildFactoryCommand.create(co, de, "coffee_roastery"))
	main.submit(BuyCommand.create(co, "VNM", "coffee", Quantity.from_units(900)))
	main.submit(ShipCommand.create(co, vn, de, "coffee", Quantity.from_units(900)))
	main.submit(BuyCommand.create(co, "VNM", "rice", Quantity.from_units(2000)))
	main.submit(ShipCommand.create(co, vn, cn, "rice", Quantity.from_units(2000)))
	s.advance_days(50)
	main.submit(BuyCommand.create(co, "VNM", "coffee", Quantity.from_units(250)))
	if InventoryQueries.available(w, vn, "coffee") > 0:
		main.submit(ShipCommand.create(co, vn, de, "coffee", InventoryQueries.available(w, vn, "coffee")))
	var rice: int = InventoryQueries.available(w, cn, "rice")
	if rice > 0:
		main.submit(SellCommand.create(co, cn, "rice", rice))
	s.advance_days(25)
	var roasted: int = InventoryQueries.available(w, de, "roasted_coffee")
	if roasted > 0:
		main.submit(SellCommand.create(co, de, "roasted_coffee", roasted / 2))
	main.submit(BuyCommand.create(co, "VNM", "coffee", Quantity.from_units(200)))
	if InventoryQueries.available(w, vn, "coffee") > 0:
		main.submit(ShipCommand.create(co, vn, de, "coffee", InventoryQueries.available(w, vn, "coffee")))
	main.submit(BuyCommand.create(co, "VNM", "rice", Quantity.from_units(150)))
	main.submit(ShipCommand.create(co, vn, cn, "rice", Quantity.from_units(150)))
	main.submit(BuyCommand.create(co, "BRA", "coffee", Quantity.from_units(10))) # lỗi có chủ đích: chưa có kho ở Brazil
	s.advance_days(6)
	main.select_country("DEU")
