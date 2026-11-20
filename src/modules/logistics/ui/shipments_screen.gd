extends ScreenBase
## Vận tải: các chuyến hàng đang đi đường.

var _list: VBoxContainer


func setup() -> void:
	var root := UI.vbox(12)
	add_child(root)
	root.add_child(header("SHIP_TITLE", "SHIP_SUBTITLE"))
	_list = UI.vbox(10)
	root.add_child(UI.scroll(_list))


func refresh() -> void:
	var w: WorldState = world()
	UI.clear(_list)
	var shipments: Array[Dictionary] = LogisticsQueries.shipments_of(w, company())
	if shipments.is_empty():
		var l := UI.label(Loc.t("SHIP_EMPTY"), "MutedLabel")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(l)
		return
	var card := UI.card()
	var g := UI.grid(7, 18, 8)
	for h: String in ["COL_COMMODITY", "COL_QTY", "COL_ROUTE", "COL_PROGRESS", "COL_ETA", "COL_VALUE", "COL_STATUS"]:
		g.add_child(UI.label(Loc.t(h), "MutedLabel"))
	for s in shipments:
		var kid: String = str(s["commodity"])
		var name_box := UI.hbox(6)
		name_box.add_child(UI.color_dot(content().commodity(kid).color, 8))
		name_box.add_child(UI.label(Fmt.commodity(kid)))
		g.add_child(name_box)
		g.add_child(UI.right(UI.label(Fmt.qty(int(s["qty"])))))
		g.add_child(UI.label("%s → %s" % [Fmt.country(str(s["from_country"])), Fmt.country(str(s["to_country"]))]))
		g.add_child(UI.progress(LogisticsQueries.progress(w, s), 1.0, AppTheme.ACCENT, 160))
		g.add_child(UI.label(Loc.t("SHIP_ETA_VALUE", {"date": Fmt.date(int(s["arrive_day"])), "days": maxi(0, int(s["arrive_day"]) - w.day)})))
		g.add_child(UI.right(UI.label(Fmt.money(int(s["value"]), true))))
		var delayed: bool = int(s["delayed_days"]) > 0
		g.add_child(UI.label(Loc.t("SHIP_DELAYED", {"days": s["delayed_days"]}) if delayed else Loc.t("SHIP_ON_TIME"), "", AppTheme.WARN if delayed else AppTheme.GOOD))
	card.add_child(g)
	_list.add_child(card)
