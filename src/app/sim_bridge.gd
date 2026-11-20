extends Node
## Cầu nối domain event (mô phỏng) -> Godot signal (UI). UI không đọc trực tiếp hàng đợi event.

signal events_published(events: Array)

const LOG_LIMIT: int = 300

## Nhật ký event gần nhất (cho màn hình Tin tức).
var log_entries: Array[SimEvent] = []


func publish(events: Array[SimEvent]) -> void:
	if events.is_empty():
		return
	for e in events:
		log_entries.append(e)
	while log_entries.size() > LOG_LIMIT:
		log_entries.pop_front()
	events_published.emit(events)


func clear() -> void:
	log_entries.clear()
