class_name AccountDef
extends RefCounted
## Tài khoản kế toán (hệ thống tài khoản trong data/*/accounts.json).

enum Kind { ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE }

var id: String
var code: String
var name_key: String
var kind: Kind = Kind.ASSET


static func from_dict(d: Dictionary, errors: Array[String]) -> AccountDef:
	var a := AccountDef.new()
	a.id = ContentUtil.req_str(d, "id", errors, "account")
	a.code = str(d.get("code", ""))
	a.name_key = str(d.get("name_key", "ACC_" + a.id.to_upper()))
	match str(d.get("kind", "")):
		"asset": a.kind = Kind.ASSET
		"liability": a.kind = Kind.LIABILITY
		"equity": a.kind = Kind.EQUITY
		"revenue": a.kind = Kind.REVENUE
		"expense": a.kind = Kind.EXPENSE
		_: errors.append("%s: kind không hợp lệ" % a.id)
	return a


func is_balance_sheet() -> bool:
	return kind == Kind.ASSET or kind == Kind.LIABILITY or kind == Kind.EQUITY
