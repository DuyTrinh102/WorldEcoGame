class_name WorldModuleState
extends ModuleState

var modifiers: ModifierStack = ModifierStack.new()


static func of(world: WorldState) -> WorldModuleState:
	return world.get_state("world") as WorldModuleState


func to_dict() -> Dictionary:
	return {"modifiers": modifiers.to_array()}


func from_dict(d: Dictionary) -> void:
	modifiers = ModifierStack.new()
	modifiers.from_array(SaveUtil.arr(d, "modifiers"))
