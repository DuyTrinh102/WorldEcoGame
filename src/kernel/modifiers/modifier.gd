class_name Modifier
extends RefCounted
## Một tác động lên chỉ số mô phỏng: thuế quan, thiên tai, mùa vụ, công nghệ...
## target ví dụ: "country:VNM", "commodity:coffee", "market:VNM/coffee", "company:co_000001"
## stat ví dụ: "market.production", "market.demand", "logistics.freight"

enum Op { ADD, MULTIPLY }

var id: String = ""
var source: String = ""
var target: String = ""
var stat: String = ""
var op: Op = Op.MULTIPLY
var value: float = 1.0
var start_day: int = 0
var end_day: int = -1   ## -1 = vô thời hạn


func is_active(day: int) -> bool:
	return day >= start_day and (end_day < 0 or day <= end_day)


func to_dict() -> Dictionary:
	return {"id": id, "source": source, "target": target, "stat": stat, "op": int(op), "value": value, "start_day": start_day, "end_day": end_day}


static func from_dict(d: Dictionary) -> Modifier:
	var m := Modifier.new()
	m.id = SaveUtil.s(d, "id")
	m.source = SaveUtil.s(d, "source")
	m.target = SaveUtil.s(d, "target")
	m.stat = SaveUtil.s(d, "stat")
	m.op = SaveUtil.i(d, "op", Op.MULTIPLY) as Op
	m.value = SaveUtil.f(d, "value", 1.0)
	m.start_day = SaveUtil.i(d, "start_day")
	m.end_day = SaveUtil.i(d, "end_day", -1)
	return m
