extends ScreenBase
## Nhật ký tin tức & sự kiện.

var _list: VBoxContainer


func setup() -> void:
	var v := UI.vbox(10)
	add_child(v)
	v.add_child(header("NEWS_TITLE", "NEWS_SUBTITLE"))
	_list = UI.vbox(4)
	v.add_child(UI.scroll(_list))


func refresh() -> void:
	UI.clear(_list)
	var entries: Array = main.bridge.log_entries
	if entries.is_empty():
		_list.add_child(UI.label(Loc.t("TICKER_EMPTY"), "MutedLabel"))
	for i in range(entries.size() - 1, -1, -1):
		var e: SimEvent = entries[i]
		var row := UI.hbox(12)
		row.add_child(UI.label(Fmt.date(e.day), "MutedLabel"))
		var color: Color = AppTheme.WARN if e.importance >= SimEvent.Importance.HIGH else (AppTheme.MUTED if e.importance == SimEvent.Importance.LOW else AppTheme.TEXT)
		var l := UI.label(Fmt.event_text(e), "", color)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		_list.add_child(row)
