class_name WorldModule
extends SimModule
## Quốc gia, vị trí cảng, khoảng cách, modifier toàn cục.


func get_id() -> String:
	return "world"


func register(ctx: ModuleContext) -> void:
	ctx.register_state(WorldModuleState)
	ctx.register_system(ModifierCleanupSystem.new())


func on_new_game(world: WorldState, _ctx: TickContext, _scenario: Dictionary) -> void:
	var st: WorldModuleState = WorldModuleState.of(world)
	st.modifiers = ModifierStack.new()


class ModifierCleanupSystem extends SimSystem:
	func get_id() -> String:
		return "world.modifier_cleanup"

	func get_phase() -> SimPhase.Phase:
		return SimPhase.Phase.PERIOD_CLOSE

	func get_frequency() -> SimSystem.Frequency:
		return SimSystem.Frequency.MONTHLY

	func run(world: WorldState, ctx: TickContext) -> void:
		WorldModuleState.of(world).modifiers.remove_expired(ctx.day)
