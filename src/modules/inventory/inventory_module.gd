class_name InventoryModule
extends SimModule
## Kho bãi và tồn kho theo kho/hàng hóa, giá vốn bình quân gia quyền.


func get_id() -> String:
	return "inventory"


func get_dependencies() -> Array[String]:
	return ["world", "corporate", "finance"]


func register(ctx: ModuleContext) -> void:
	ctx.register_state(InventoryState)
	ctx.register_system(StorageCostSystem.new())
	ctx.register_command(OpenWarehouseCommand.TYPE, OpenWarehouseCommand)
	ctx.register_ui_screen("warehouses", "res://src/modules/inventory/ui/warehouses_screen.gd", "NAV_WAREHOUSES", 20)


func on_new_game(world: WorldState, ctx: TickContext, scenario: Dictionary) -> void:
	for country: Variant in scenario.get("start_warehouses", []):
		InventoryService.create_warehouse(world, ctx, world.player_company_id, str(country))
