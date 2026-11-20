class_name TradeModule
extends SimModule
## Mua bán với thị trường: lệnh mua (trả tiền ngay), lệnh bán (ghi công nợ, thu tiền sau N ngày).


func get_id() -> String:
	return "trade"


func get_dependencies() -> Array[String]:
	return ["market", "inventory", "finance"]


func register(ctx: ModuleContext) -> void:
	ctx.register_state(TradeState)
	ctx.register_system(ReceivablesSystem.new())
	ctx.register_command(BuyCommand.TYPE, BuyCommand)
	ctx.register_command(SellCommand.TYPE, SellCommand)
	ctx.register_ui_screen("market", "res://src/modules/trade/ui/market_screen.gd", "NAV_MARKET", 10)
