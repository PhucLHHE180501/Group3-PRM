# HƯỚNG DẪN KIẾN TRÚC & PHÂN CHIA NHIỆM VỤ DỰ ÁN (ROLE-BASED / FEATURE-FIRST)

Dự án đã được tái cấu trúc (refactored) theo mô hình **Feature-First Architecture** chia theo từng vai trò (Role-based Modules): **Customer**, **Barber**, **Receptionist** và **Auth**.

---

## 1. Cấu Trúc Thư Mục Tổng Quan (`lib/`)

```
lib/
├── core/                                 # Cấu hình cốt lõi dùng chung toàn ứng dụng
│   ├── theme/
│   │   └── app_theme.dart                # Giao diện, màu sắc, Dark/Light Theme
│   └── constants/                        # Hằng số chung (assets, config,...)
│
├── shared/                               # Dữ liệu & dịch vụ dùng chung giữa các Role
│   ├── models/                           # Toàn bộ Data Models
│   │   ├── barber_model.dart             # Model thợ cắt tóc
│   │   ├── booking_model.dart            # Model lịch đặt
│   │   ├── review_model.dart             # Model đánh giá
│   │   ├── schedule_model.dart           # Model ca làm việc / khung giờ
│   │   ├── service_model.dart            # Model dịch vụ cắt gội
│   │   ├── transaction_model.dart        # Model lịch sử giao dịch
│   │   └── user_model.dart               # Model tài khoản người dùng
│   ├── services/
│   │   └── mock_data_service.dart        # Tầng Mock Data / State trung tâm
│   └── widgets/
│       └── add_review_dialog.dart        # Các Dialog, Button dùng chung
│
├── features/                             # CÁC PHÂN HỆ THEO VAI TRÒ (DÀNH CHO CHIA NHIỆM VỤ)
│   ├── auth/                             # PHÂN HỆ XÁC THỰC & ĐĂNG NHẬP
│   │   └── screens/
│   │       └── login_screen.dart         # Màn hình đăng nhập & chuyển hướng theo role
│   │
│   ├── customer/                         # PHÂN HỆ KHÁCH HÀNG (CUSTOMER)
│   │   ├── screens/
│   │   │   ├── home/                     # Màn hình Trang chủ
│   │   │   │   └── home_screen.dart
│   │   │   ├── barber/                   # Màn hình danh sách & chi tiết Barber
│   │   │   │   ├── barber_list_screen.dart
│   │   │   │   └── barber_detail_screen.dart
│   │   │   ├── booking/                  # Màn hình đặt lịch hẹn
│   │   │   │   └── booking_screen.dart
│   │   │   ├── history/                  # Lịch sử đơn đặt & giao dịch
│   │   │   │   └── transaction_history_screen.dart
│   │   │   ├── profile/                  # Thông tin cá nhân & chỉnh sửa
│   │   │   │   ├── profile_screen.dart
│   │   │   │   └── edit_profile_screen.dart
│   │   │   ├── support/                  # Hỗ trợ chăm sóc khách hàng
│   │   │   │   └── cskh_screen.dart
│   │   │   └── main_navigation_screen.dart # Bottom Navigation Bar của Customer
│   │   └── widgets/                      # Widget riêng của phân hệ Khách Hàng
│   │
│   ├── barber/                           # PHÂN HỆ THỢ CẮT TÓC (BARBER / STAFF)
│   │   ├── screens/
│   │   │   └── staff_dashboard_screen.dart # Dashboard quản lý ca làm, lịch hẹn trong ngày
│   │   └── widgets/                      # Widget riêng của phân hệ Barber
│   │
│   └── receptionist/                     # PHÂN HỆ LỄ TÂN (RECEPTIONIST)
│       ├── screens/
│       │   └── receptionist_dashboard_screen.dart # Tiếp nhận khách, check-in, duyệt booking
│       └── widgets/                      # Widget riêng của phân hệ Lễ Tân
│
└── main.dart                             # Entry point khởi chạy ứng dụng
```

---

## 2. Bảng Phân Chia Nhiệm Vụ Thành Viên Nhóm

| Thành viên / Phụ trách | Thư mục phụ trách chính | Các chức năng chính |
| :--- | :--- | :--- |
| **Thành viên 1: Customer (Khách hàng)** | `lib/features/customer/` | - Trang chủ: xem banner, dịch vụ hot, thợ tiêu biểu.<br>- Danh sách thợ & Chi tiết thợ (xem bio, rating, review).<br>- Đặt lịch hẹn (chọn ngày, giờ, thợ, dịch vụ).<br>- Xem lịch sử đặt lịch & hóa đơn giao dịch.<br>- Quản lý hồ sơ cá nhân & CSKH. |
| **Thành viên 2: Barber (Thợ cắt tóc)** | `lib/features/barber/` | - Dashboard thợ: xem danh sách khách hẹn theo ngày/giờ.<br>- Cập nhật trạng thái ca cắt tóc (đang cắt, đã hoàn thành).<br>- Quản lý lịch rảnh / bận.<br>- Xem doanh thu/hoa hồng cá nhân (tính năng mở rộng). |
| **Thành viên 3: Receptionist (Lễ tân)** | `lib/features/receptionist/` | - Dashboard lễ tân: điều phối tất cả booking của salon.<br>- Check-in khi khách đến tiệm.<br>- Tạo booking nhanh tại quầy (walk-in khách vãng lai).<br>- Xác nhận thanh toán & in hóa đơn. |
| **Trưởng nhóm / Core & Auth** | `lib/core/`, `lib/shared/`, `lib/features/auth/` | - Màn hình đăng nhập & phân quyền.<br>- MockDataService hoặc kết nối API Backend.<br>- Thiết lập Theme chung, Font, Base Widget.<br>- Merge code & Review Pull Request. |

---

## 3. Quy Tắc Phối Hợp Git Để Tránh Conflict

1. **Mỗi thành viên làm việc trong folder của mình:**
   - Thành viên làm Customer chỉ sửa và thêm file trong `lib/features/customer/`.
   - Thành viên làm Barber chỉ sửa và thêm file trong `lib/features/barber/`.
   - Thành viên làm Receptionist chỉ sửa và thêm file trong `lib/features/receptionist/`.
2. **Khi cần dùng chung Data / Service:**
   - Gọi thông qua `package:barber_booking_app/shared/models/...` hoặc `package:barber_booking_app/shared/services/...`.
   - Nếu cần thêm trường dữ liệu vào Model (ví dụ: thêm voucher, ghi chú), trao đổi với Trưởng nhóm phụ trách `shared/` để thống nhất trước khi commit.
3. **Widget dùng chung vs Widget riêng:**
   - Widget chỉ dùng cho 1 vai trò -> đặt trong `lib/features/<role>/widgets/`.
   - Widget tái sử dụng ở 2 vai trò trở lên (ví dụ button, dialog xác nhận) -> đưa lên `lib/shared/widgets/`.
