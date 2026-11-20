# GDD — Mô hình kinh tế (đã triển khai ở prototype M2)

> Tài liệu mô tả **đúng những gì code đang chạy** (`src/modules/market/sim/models/detailed_market_model.gd`).
> Mọi tham số nằm trong `data/base/settings.json` và `data/base/commodities/*.json` — chỉnh để cân bằng không cần build lại.

## 1. Đơn vị
- 1 tick = 1 ngày. Chốt sổ cuối tháng. Ngày bắt đầu: 01/01/2027.
- Giá: USD/tấn (`float` trong thị trường — chỉ số; giao dịch quy đổi sang `UnitPrice` số nguyên).
- Prototype hạch toán toàn bộ bằng USD (tỷ giá để M3).

## 2. Hiệu chỉnh khi tạo thế giới
Cho mỗi hàng hóa *k*:
```
raw_c   = dân số_c × (GDP/người_c / 10 000)^(độ co giãn thu nhập_k) × khẩu vị_c,k
cầu_c   = raw_c × (Σ sản lượng_k / Σ raw)          → tổng cầu thế giới = tổng cung ở giá tham chiếu
quy mô_c = max(sản lượng_c, cầu_c)
tồn kho ban đầu = quy mô_c / 365 × target_cover_days (90)
```
Sau đó chạy "khởi động" 240 ngày để giá các nước phân hóa và có lịch sử biểu đồ.

## 3. Vòng cập nhật hằng ngày (mỗi hàng hóa)
```
sản lượng_c = SL_năm/365 × mùa_vụ[tháng] × (EMA giá 90 ngày / P_ref)^(độ co giãn cung) × (1 ± 5% nhiễu) × modifier
cầu_c       = cầu_năm/365 × (P_c / P_ref)^(độ co giãn giá) × modifier
giá thế giới W = Σ P_c·quy mô_c / Σ quy mô_c
thương mại NPC mong muốn_c = trade_rate × quy mô_c/365 × (P_c − W)/W      (+ nhập, − xuất)
   → xuất khẩu bị giới hạn ≤ 50% (tồn + sản lượng); tổng nhập được co lại = tổng xuất (bảo toàn hàng)
tồn kho_c  = max(0, tồn + sản lượng + dòng thương mại − cầu)
ngày tồn   = tồn / (quy mô/365)
giá mục tiêu = P_ref × (ngày tồn / 90)^(−stock_price_sensitivity)       (kẹp trong [0.25, 4] × P_ref)
giá mới    = giá × (1 + clamp(adjust_speed × (mục tiêu/giá − 1), ±max_daily_change) + nhiễu N(0, noise))
```
**Vì sao "giá mục tiêu theo mức tồn kho"?** Phiên bản đầu cho giá thay đổi theo *tốc độ* tồn kho → hệ hai tích phân,
dao động tăng dần (giá lúa mì rơi xuống sàn sau 4 năm). Bộ điều khiển tỉ lệ hiện tại ổn định: 10 năm × 12 hàng hóa,
giá thế giới dao động 0.9–1.1 × P_ref, chênh lệch giữa các nước ±10–20% (cơ hội arbitrage sau khi trừ cước).

## 4. Người chơi tác động thị trường
```
độ sâu   = quy mô/365 × trade_depth_days (30)
giá khớp = P × (1 ± 0.5 × slippage × Q/độ sâu)        (mua +, bán −)
sau lệnh: tồn kho NPC ∓ Q, giá × (1 ± slippage × Q/độ sâu)
lệnh mua tối đa = 50% tồn kho thị trường
```

## 5. Chuỗi giá trị & chi phí
| Khoản | Cách tính | Ghi sổ |
|------|-----------|-------|
| Mua hàng | trả tiền ngay | Nợ Hàng tồn kho / Có Tiền |
| Vận chuyển | max(15, 12 + 4.5 × km/1000) $/t; km = vòng lớn × 1.3; tốc độ 650 km/ngày + 2 ngày cảng; 12% trễ 2–7 ngày | cước **vốn hóa** vào giá vốn hàng |
| Sản xuất | đầu vào theo BOM + chi phí biến đổi/t | giá vốn TP = NVL + biến đổi |
| Bán hàng | ghi doanh thu + phải thu, tiền về sau 30 ngày | Nợ Phải thu / Có Doanh thu; Nợ GVHB / Có Tồn kho |
| Kho | mở $150K (chi phí), thuê $12K/tháng + $1.5/t/tháng, sức chứa 30 000 t | chi phí kho |
| Nhà máy | vốn đầu tư → TSCĐ, khấu hao đường thẳng; chi phí cố định/tháng (30% khi tạm dừng) | |
| Vay | hạn mức = max($3M, vốn chủ sở hữu); 8%/năm; thấu chi 18%/năm khi tiền âm | |

## 6. Nhà máy (giá trị cân bằng ban đầu)
| Nhà máy | Vốn | Xây | Công suất | Công thức | Biến đổi | Cố định/tháng |
|---------|-----|-----|-----------|-----------|----------|---------------|
| Xưởng rang xay | $2.5M | 45 ngày | 12 t/ngày | 1.19 cà phê nhân | $1 100/t | $45K |
| Nhà máy thép | $6M | 90 ngày | 100 t/ngày | 1.6 quặng sắt + 0.75 than | $230/t | $120K |
| Nhà máy thực phẩm | $3M | 60 ngày | 40 t/ngày | 0.7 lúa mì + 0.35 đậu nành + 0.2 gạo | $700/t | $70K |
| Nhà máy phân bón | $4M | 75 ngày | 150 t/ngày | 0.35 dầu thô + 0.6 than | $70/t | $80K |

## 7. Việc cân bằng còn mở (M3)
- Nền kinh tế tĩnh (dân số, GDP không tăng) — thêm tăng trưởng + sản lượng tăng tương ứng.
- Hao hụt hàng dễ hỏng (`monthly_loss_rate` đã có trong dữ liệu, chưa áp dụng).
- Thương mại NPC chưa tốn cước → chênh lệch giá chưa phản ánh khoảng cách địa lý.
- Chưa có đối thủ AI cạnh tranh cùng cơ hội arbitrage.
