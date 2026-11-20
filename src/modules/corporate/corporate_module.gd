class_name CorporateModule
extends SimModule
## Công ty / tập đoàn. Prototype: chỉ công ty của người chơi.


func get_id() -> String:
	return "corporate"


func get_dependencies() -> Array[String]:
	return ["world"]


func register(ctx: ModuleContext) -> void:
	ctx.register_state(CorporateState)


func on_new_game(world: WorldState, _ctx: TickContext, scenario: Dictionary) -> void:
	var st: CorporateState = CorporateState.of(world)
	var id: String = world.new_id("co")
	st.companies[id] = {
		"id": id,
		"name": str(scenario.get("company_name", "Player Co")),
		"home_country": str(scenario.get("home_country", "VNM")),
		"is_player": true,
		"color": str(scenario.get("company_color", "#e0b04a")),
		"founded_day": world.day,
	}
	world.player_company_id = id
