class_name ProductionModule
extends SimModule
## Nhà máy: xây dựng, công thức BOM, công suất, chi phí biến đổi, chi phí cố định, khấu hao.


func get_id() -> String:
	return "production"


func get_dependencies() -> Array[String]:
	return ["world", "finance", "inventory"]


func register(ctx: ModuleContext) -> void:
	ctx.register_state(ProductionState)
	ctx.register_system(ProductionSystem.new())
	ctx.register_system(FactoryCostSystem.new())
	ctx.register_command(BuildFactoryCommand.TYPE, BuildFactoryCommand)
	ctx.register_command(SetFactoryActiveCommand.TYPE, SetFactoryActiveCommand)
	ctx.register_ui_screen("factories", "res://src/modules/production/ui/factories_screen.gd", "NAV_FACTORIES", 30)
