class_name Ledger
extends RefCounted
## Sổ cái kép. MỌI biến động tiền/tài sản đều phải đi qua Ledger.post().
## Quy ước số dư: Nợ (debit) dương, Có (credit) âm. Tổng các dòng của một bút toán phải = 0.

const JOURNAL_LIMIT: int = 400


static func dr(account_id: String, amount: int) -> Array:
	return [account_id, amount]


static func cr(account_id: String, amount: int) -> Array:
	return [account_id, -amount]


## Ghi bút toán. Trả về false (và không ghi gì) nếu Nợ ≠ Có.
static func post(world: WorldState, day: int, company_id: String, memo_key: String, lines: Array, memo_args: Dictionary = {}) -> bool:
	var total: int = 0
	var clean: Array = []
	for line: Array in lines:
		var amount: int = int(line[1])
		total += amount
		if amount != 0:
			clean.append([str(line[0]), amount])
	if total != 0:
		push_error("Ledger: bút toán lệch %d cent (%s)" % [total, memo_key])
		return false
	if clean.is_empty():
		return true
	var st: FinanceState = FinanceState.of(world)
	var bal: Dictionary = st.company_balances(company_id)
	for line: Array in clean:
		bal[line[0]] = int(bal.get(line[0], 0)) + int(line[1])
	st.journal.append({"day": day, "company": company_id, "memo": memo_key, "args": memo_args, "lines": clean})
	if st.journal.size() > JOURNAL_LIMIT:
		st.journal.pop_front()
	return true
