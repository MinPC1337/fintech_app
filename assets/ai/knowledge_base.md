# Smart Finance — Tài liệu & Hướng dẫn Đầy đủ

## TỔNG QUAN ỨNG DỤNG

Smart Finance là ứng dụng quản lý tài chính cá nhân và nhóm dành cho người dùng Việt Nam.

Các tính năng chính:
- Quản lý ví cá nhân (nạp, rút, chuyển tiền)
- Theo dõi ngân sách chi tiêu theo danh mục hàng tháng
- Quản lý ví nhóm (góp quỹ, chia tiền, xử lý nợ)
- Xem lịch sử giao dịch đầy đủ
- Nhận thông báo giao dịch và nhắc nợ

---

## CHI TIẾT TÍNH NĂNG

### 1. VÍ CÁ NHÂN (Trang home)

**Số dư ví:**
- Hiển thị tổng số dư hiện tại của ví cá nhân
- Cập nhật real-time sau mỗi giao dịch

**Nạp tiền (deposit):**
- Chuyển tiền từ ví MoMo vào Smart Finance
- Cần nhập: Số điện thoại MoMo nguồn + Số tiền muốn nạp
- Tiền vào ví ngay sau khi giao dịch thành công
- Nhận thông báo xác nhận

**Rút tiền (transfer):**
- Chuyển tiền từ Smart Finance ra ví MoMo
- Cần nhập: Số điện thoại MoMo đích + Số tiền muốn rút
- Kiểm tra số dư trước khi thực hiện
- Nhận thông báo xác nhận

**Chuyển tiền nội bộ (send_money):**
- Chuyển tiền cho người dùng khác trong app Smart Finance
- Cần nhập: Số tài khoản Smart Finance của người nhận + Số tiền
- Nhận tiền ngay lập tức, cả hai bên nhận thông báo
- Không mất phí giao dịch

**Nhận tiền (QR):**
- Tạo mã QR chứa số tài khoản cá nhân
- Chia sẻ QR để người khác quét và chuyển tiền vào ví
- Có thể lưu QR hoặc chia sẻ qua các ứng dụng khác

---

### 2. NGÂN SÁCH (Trang budget)

**Thiết lập ngân sách:**
- Tạo hạn mức chi tiêu cho từng danh mục mỗi tháng
- Chọn tháng/năm áp dụng
- Có thể cập nhật hạn mức bất cứ lúc nào

**Danh mục chi tiêu có sẵn:**
- Ăn uống (food)
- Di chuyển (transport)
- Mua sắm (shopping)
- Giải trí (entertainment)
- Sức khỏe (health)
- Khác (other)

**Theo dõi chi tiêu:**
- So sánh chi tiêu thực tế vs. ngân sách đặt ra theo từng danh mục
- Biểu đồ tròn thống kê phân bổ chi tiêu theo tháng
- Cảnh báo màu đỏ khi chi tiêu vượt ngân sách (over-budget)
- Theo dõi tự động dựa trên giao dịch trong app

**Thêm ngân sách mới:**
- Bấm nút "+" hoặc "Thêm ngân sách"
- Chọn danh mục → Nhập hạn mức → Chọn tháng/năm → Lưu

---

### 3. VÍ NHÓM (Trang group_wallet)

**Tạo ví nhóm:**
- Đặt tên nhóm (VD: "Du lịch Đà Nẵng", "Quỹ nhậu cuối tuần")
- Tùy chọn màu sắc cho nhóm
- Người tạo tự động là trưởng nhóm (admin)

**Mời thành viên:**
- Nhập email của người muốn mời
- Hệ thống gửi lời mời → người kia nhận thông báo
- Người nhận có thể chấp nhận hoặc từ chối lời mời
- Cũng có thể chia sẻ link mời

**Góp tiền vào quỹ nhóm:**
- Thành viên góp tiền từ ví cá nhân vào ví nhóm
- Nhập số tiền muốn góp
- Tiền trừ từ ví cá nhân, cộng vào ví nhóm
- Lịch sử góp tiền được ghi lại

**Rút tiền từ quỹ nhóm:**
- Chỉ trưởng nhóm (admin) mới có quyền rút
- Nhập số tiền + ghi chú mục đích rút
- Tiền vào ví cá nhân của admin

**Chia tiền chi tiêu (Split Expense):**
- Nhập tổng chi phí + ghi chú (VD: "Tiền ăn tối")
- Chọn những thành viên tham gia chia tiền
- Hệ thống tự chia đều → tạo danh sách nợ
- Mỗi người nhận thông báo về số tiền phải trả

**Thanh toán nợ (Settle Debt):**
- Người nợ bấm "Thanh toán" trên khoản nợ của mình
- Tiền tự động trừ từ ví cá nhân người nợ → cộng vào ví người cho vay
- Cả hai nhận thông báo xác nhận

**Nhắc nợ:**
- Người cho vay có thể nhắc thành viên chưa trả nợ
- Gửi thông báo đến người nợ

**Quản lý thành viên (chỉ admin):**
- Xem danh sách thành viên
- Kick (xóa) thành viên ra khỏi nhóm
- Không thể tự xóa mình

**Giải tán nhóm (chỉ admin):**
- Chỉ trưởng nhóm có thể giải tán
- Cần xử lý tất cả nợ trước khi giải tán
- Toàn bộ dữ liệu nhóm bị xóa

---

### 4. THÔNG BÁO (Trang notifications)

Các loại thông báo:
- Nhận tiền thành công
- Chuyển tiền thành công
- Rút tiền thành công
- Được mời vào nhóm (có thể chấp nhận/từ chối ngay từ thông báo)
- Nhắc nợ từ thành viên nhóm
- Chia tiền nhóm — bạn cần trả nợ

Thao tác:
- Đánh dấu đã đọc từng thông báo
- Đánh dấu đã đọc tất cả

---

### 5. LỊCH SỬ GIAO DỊCH (Trang transaction_history)

Hiển thị:
- Toàn bộ giao dịch cá nhân (nạp, rút, chuyển, nhận)
- Thời gian giao dịch
- Số tiền và loại giao dịch (thu/chi)
- Ghi chú của giao dịch

---

### 6. CÀI ĐẶT & HỒ SƠ

**Hồ sơ cá nhân (profile):**
- Xem thông tin: tên, email, số tài khoản Smart Finance, ảnh đại diện
- Cập nhật tên hiển thị
- Thay đổi ảnh đại diện

**Cài đặt (settings):**
- Đổi mật khẩu
- Đăng xuất khỏi tài khoản

---

## CÂU HỎI THƯỜNG GẶP (FAQ)

### Q: Tôi quên mật khẩu, phải làm sao?
A: Trên màn hình đăng nhập, bấm "Quên mật khẩu" → Nhập email đã đăng ký → Hệ thống gửi email khôi phục mật khẩu.

### Q: Số tài khoản Smart Finance của tôi là gì?
A: Vào trang Hồ sơ (Profile) → Số tài khoản hiển thị ngay trên màn hình. Đây là mã dùng để người khác chuyển tiền vào ví của bạn.

### Q: Tôi có thể nạp bao nhiêu tiền vào ví?
A: Không có giới hạn tối đa. Số tiền nạp phụ thuộc vào số dư ví MoMo của bạn.

### Q: Mất bao lâu để tiền vào ví sau khi nạp?
A: Ngay lập tức sau khi giao dịch được xác nhận thành công.

### Q: Tôi có thể chuyển tiền cho bao nhiêu người trong một lần?
A: Hiện tại mỗi giao dịch chỉ chuyển cho 1 người. Để chia tiền nhóm, dùng tính năng "Chia tiền" trong Ví nhóm.

### Q: Ví nhóm khác ví cá nhân như thế nào?
A: Ví cá nhân là ví riêng của bạn để nạp/rút/chuyển tiền hàng ngày. Ví nhóm là quỹ chung của nhiều người, dùng để góp tiền chung và chia chi phí trong nhóm.

### Q: Admin ví nhóm có những quyền gì?
A: Admin có thể: rút tiền từ quỹ nhóm, kick thành viên, giải tán nhóm. Các thành viên thường chỉ có thể xem và góp tiền.

### Q: Nếu tôi bị kick khỏi nhóm thì tiền tôi đã góp có bị mất không?
A: Tiền đã góp vào quỹ nhóm sẽ không được hoàn lại tự động khi bị kick. Cần thỏa thuận với admin trước.

### Q: Tôi có thể xem lịch sử giao dịch nhóm không?
A: Có. Vào Ví nhóm → chọn nhóm → bấm "Lịch sử giao dịch".

### Q: Thông báo nhắc nợ hoạt động như thế nào?
A: Người cho vay (lender) bấm nút nhắc nợ → người nợ (borrower) nhận thông báo trên app. Chức năng này giúp nhắc nhở một cách lịch sự mà không cần nhắn tin thủ công.

### Q: Tôi muốn đổi tên hiển thị, làm thế nào?
A: Vào Hồ sơ (Profile) → Bấm nút chỉnh sửa → Thay đổi tên → Lưu.

### Q: Số dư của tôi hiện tại là bao nhiêu?
A: Tôi có thể kiểm tra số dư thực tế của bạn ngay bây giờ. Ngoài ra, số dư luôn hiển thị trên trang chủ (Home).

### Q: Ứng dụng có an toàn không?
A: Smart Finance sử dụng Firebase Authentication (xác thực email/mật khẩu) và Firestore Security Rules để bảo vệ dữ liệu. Mỗi người dùng chỉ có thể truy cập dữ liệu của chính mình.

---

## DANH SÁCH TRANG & ROUTE

| Route | Mô tả |
|-------|-------|
| home | Trang chủ, xem số dư ví cá nhân |
| budget | Quản lý ngân sách theo danh mục |
| group_wallet | Danh sách ví nhóm |
| settings | Cài đặt tài khoản |
| deposit | Nạp tiền từ MoMo vào Smart Finance |
| transfer | Rút tiền từ Smart Finance ra MoMo |
| send_money | Chuyển tiền nội bộ cho user khác |
| profile | Hồ sơ cá nhân |
| notifications | Trung tâm thông báo |
| transaction_history | Lịch sử giao dịch cá nhân |

---

## XỬ LÝ LỖI PHỔ BIẾN

- **"Số dư không đủ"**: Kiểm tra lại số dư ví trước khi thực hiện giao dịch.
- **"Không tìm thấy người nhận"**: Kiểm tra lại số tài khoản hoặc email đã nhập đúng chưa.
- **"Không thể kết nối mạng"**: Kiểm tra kết nối internet và thử lại.
- **"Phiên đăng nhập hết hạn"**: Đăng xuất và đăng nhập lại.
- **"Lời mời đã được xử lý"**: Lời mời này đã được chấp nhận hoặc từ chối trước đó.
