class_name MarketModule
extends SimModule
## Thị trường hàng hóa theo quốc gia: cung, cầu, tồn kho, giá, thương mại quốc tế (NPC).


func get_id() -> String:
	return "market"


func get_dependencies() -> Array[String]:
	return ["world"]


func register(ctx: ModuleContext) -> void:
	ctx.register_state(MarketState)
	ctx.register_system(MarketSystem.new())


func on_new_game(world: WorldState, ctx: TickContext, _scenario: Dictionary) -> void:
	var st: MarketState = MarketState.of(world)
	DetailedMarketModel.initialize(st, ctx.content)
	# Chạy "khởi động" để thị trường phân hóa giá trước khi người chơi vào game.
	var warmup: int = ctx.content.setting_i("market.warmup_days", 240)
	var mods: ModifierStack = WorldQueries.modifiers(world)
	for i in warmup:
		var day: int = world.day - warmup + i
		var wctx := TickContext.new(day, ctx.content, world.world_seed)
		DetailedMarketModel.step_all(st, wctx, mods)
		MarketSystem.record(st, wctx, false)
