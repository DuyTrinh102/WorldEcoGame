# CLAUDE.md — Hướng dẫn cho Claude Code

Game: **World Economy: Build Your Empire** — mô phỏng kinh tế toàn cầu, Godot 4.x, GDScript.
Đọc trước khi làm: `docs/ARCHITECTURE.md` (kiến trúc), `docs/ROADMAP.md` (đang ở mốc nào), `docs/DECISIONS.md`.

## Luật kiến trúc (bắt buộc)

1. **Sim không biết UI.** Code trong `src/kernel/`, `src/core/`, `src/content/`, `src/modules/*/sim/` KHÔNG `extends Node`, KHÔNG dùng `get_tree()`, autoload, hay tham chiếu `ui/`. Chỉ `RefCounted`/`Resource`.
2. **Thay đổi state chỉ qua `SimCommand`** (từ người chơi/AI/kịch bản) hoặc bên trong `SimSystem.run()`. UI không bao giờ sửa state trực tiếp.
3. **UI chỉ đọc qua `Queries`**, ghi qua `GameSession.submit(command)`, nghe signal từ `SimBridge`.
4. **Module không sửa state của module khác** — dùng command/service/domain event của module đó.
5. **Phụ thuộc một chiều:** `core ← content ← kernel ← modules/*/sim ← persistence ← app ← ui`.
6. **Tiền không dùng float.** Dùng `Money`, `UnitPrice`, `Quantity` trong `src/core/types/`. Mọi phép tính tiền qua hàm của các kiểu này.
7. **Mọi bút toán tiền đi qua `Ledger.post()`** (sổ cái kép, Nợ = Có).
8. **Tất định:** không dùng `randf()`/`randi()` toàn cục hay thời gian thực trong sim; dùng `ctx.rng` (RngStream riêng từng system). Duyệt collection theo ID đã sắp xếp.
9. **Tham chiếu thực thể bằng ID chuỗi** (`co_000123`), không giữ object reference xuyên module.
10. **Nội dung là dữ liệu:** quốc gia/hàng hóa/công thức/sự kiện/AI profile nằm trong `data/base/*.json`, không hard-code.
11. **Đổi cấu trúc save → tăng `save_version` và viết migration** trong `src/persistence/migrations/`.

## Quy ước code

- Static typing bắt buộc cho biến, tham số, kiểu trả về.
- File/thư mục: `snake_case.gd`; `class_name` PascalCase; hằng số `UPPER_SNAKE`; ID nội dung `snake_case` (`crude_oil`), ID quốc gia ISO-3 (`VNM`).
- Module mới theo đúng khuôn: `<module>_module.gd` + `sim/{state,systems,commands,events,queries,serialization}` + `ui/`.
- Chuỗi hiển thị qua `tr("KEY")`, không hard-code tiếng Việt/Anh trong code.
- Comment/doc có thể viết tiếng Việt hoặc tiếng Anh, nhưng tên định danh bằng tiếng Anh.

## Quy trình

- Làm **một module/tính năng mỗi lần**. Không sửa nhiều module cùng lúc nếu chưa có test bao phủ.
- Logic kinh tế mới **phải có test** (`tests/unit/` mirror `src/`; chuỗi nghiệp vụ trong `tests/scenario/`).
- Trước khi commit: chạy test, validate data và lint kiến trúc (lệnh bên dưới).
- Quyết định kiến trúc mới → thêm mục vào `docs/DECISIONS.md`.
- Xong việc của mốc → tick checklist trong `docs/ROADMAP.md`.

## Lệnh

```bash
# Lần đầu sau khi clone (tạo cache class_name) — bắt buộc trước khi chạy script headless
godot --headless --import

# Chạy toàn bộ test (lọc: -- --filter=market)
godot --headless --path . -s res://tests/run_tests.gd

# Kiểm tra dữ liệu JSON + bản dịch
godot --headless --path . -s res://tools/validate_data.gd

# Kiểm tra phân lớp kiến trúc (sim không phụ thuộc UI/Node, không RNG toàn cục)
godot --headless --path . -s res://tools/lint_architecture.gd

# Chạy mô phỏng cân bằng N năm (in tóm tắt theo năm, tùy chọn xuất CSV)
godot --headless --path . -s res://tools/balance_runner.gd -- --years=10 --seed=42 [--commodity=coffee] [--csv=user://b.csv]

# Chụp màn hình mọi màn hình sau kịch bản demo (cần màn hình ảo trên Linux)
xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 -- --no-welcome --capture=/tmp/shot --demo [--soak=30]

# Export
godot --headless --export-release "Windows Desktop" build/windows/WorldEconomy.exe
```

## Lưu ý kỹ thuật đã gặp

- Script `extends SceneTree` gặp lỗi runtime trong `_init()` sẽ treo (không gọi được `quit()`): luôn chạy với `timeout`.
- Gán mảng không kiểu vào `Array[String]` gây lỗi runtime — dùng `.duplicate()` từ mảng có kiểu hoặc gán từng phần tử.
- `JSON.parse_string` trả số nguyên thành `float`: đọc save qua `SaveUtil.i/f/s/b`; số thực cần chính xác dùng `SaveUtil.floats_to_b64`.
- Label `autowrap` trong hộp thoại phải có `custom_minimum_size.x` (dùng `UI.wrap_label`), nếu không hộp thoại cao hết màn hình.
- Không đặt tên hàm `_set`, `_get` (trùng hàm ảo của Object).
