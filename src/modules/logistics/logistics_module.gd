class_name LogisticsModule
extends SimModule
## Vận tải biển giữa các kho: thời gian, cước phí, rủi ro trễ hàng.


func get_id() -> String:
	return "logistics"


func get_dependencies() -> Array[String]:
	return ["world", "finance", "inventory"]


func register(ctx: ModuleContext) -> void:
	ctx.register_state(LogisticsState)
	ctx.register_system(ShipmentSystem.new())
	ctx.register_command(ShipCommand.TYPE, ShipCommand)
	ctx.register_ui_screen("shipments", "res://src/modules/logistics/ui/shipments_screen.gd", "NAV_SHIPMENTS", 40)
