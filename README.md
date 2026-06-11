# Smart Finance (fintech_app)

Smart Finance là ứng dụng quản lý tài chính cá nhân và nhóm thông minh dành cho người dùng Việt Nam, được phát triển trên nền tảng Flutter. 
Ứng dụng giúp bạn dễ dàng theo dõi chi tiêu, quản lý ngân sách hiệu quả, và đặc biệt hỗ trợ quản lý quỹ nhóm, chia sẻ chi phí một cách minh bạch. Đặc biệt, ứng dụng tích hợp **Trợ lý AI thông minh** (Google Gemini) giúp tra cứu, tư vấn tài chính trực tiếp dựa trên dữ liệu thật của bạn.

## 🌟 Tính năng chính

- **Ví Cá Nhân**: Theo dõi số dư, thực hiện nạp/rút tiền (liên kết mô phỏng ví MoMo), chuyển tiền nội bộ nhanh chóng.
- **Ngân Sách (Budget)**: Thiết lập và giám sát chặt chẽ hạn mức chi tiêu hàng tháng theo từng danh mục (Ăn uống, Giải trí, Mua sắm...).
- **Ví Nhóm (Group Wallet)**: 
  - Tạo quỹ chung, mời bạn bè qua email.
  - Góp quỹ, rút quỹ và xem lịch sử giao dịch nhóm.
  - Tính năng "Chia tiền" (Split Expense) tự động chia đều hóa đơn và tạo danh sách nợ.
  - Quản lý công nợ nhóm, gửi thông báo nhắc nợ (Remind Debt) trực tiếp tới các thành viên.
- **Trợ Lý AI Thông Minh**: Chatbot AI hiểu sâu dữ liệu tài khoản (sử dụng Function Calling), cho phép truy vấn số dư, tình trạng ngân sách, giao dịch gần đây, ai đang nợ tiền, v.v. thông qua ngôn ngữ tự nhiên tiếng Việt.
- **Hệ thống thông báo**: Tích hợp Local Notifications và lưu trữ thông báo (Real-time).

## 🚀 Công nghệ sử dụng

- **Framework:** Flutter & Dart
- **Backend/BaaS:** Firebase (Cloud Firestore, Firebase Authentication)
- **AI Integration:** Google Generative AI SDK (Mô hình Gemini 1.5/2.0 Flash)
- **Kiến trúc:** Clean Architecture kết hợp Feature-based
- **State Management / Error Handling:** Dartz (Functional Programming), Stream Controllers,...
- **Thư viện nổi bật:** `flutter_local_notifications`, `intl`

## 📂 Cấu trúc thư mục (Architecture)

Dự án sử dụng mô hình **Clean Architecture** được chia nhỏ theo từng chức năng độc lập (Feature-driven), giúp code dễ bảo trì, dễ mở rộng:

```text
lib/
│
├── core/                   # Chứa thành phần dùng chung toàn app (services, errors, themes)
│   └── services/           # vd: local_notification_service.dart
│
├── features/               # Các module tính năng của ứng dụng
│   ├── ai_chat/            # Tính năng trợ lý ảo Gemini AI
│   │   ├── data/           # Repositories impl, Datasources (Function Handlers, Session Manager)
│   │   ├── domain/         # Entities, UseCases, Repositories interface
│   │   └── presentation/   # UI, State management cho Chat AI
│   │
│   └── group_wallet/       # Tính năng quản lý ví nhóm, chia tiền, nhắc nợ
│       ├── data/           # Remote Data Source thao tác trực tiếp với Firestore
│       └── domain/         # Xử lý business logic quản lý ví nhóm
│
├── main/                   # (Hoặc shared) Chứa các Data Models dùng chung toàn cục
│   └── data/models/        # WalletModel, TransactionModel, DebtModel...
│
└── main.dart               # Entry point của ứng dụng
```

## 🛠️ Hướng dẫn cài đặt và khởi chạy (Getting Started)

Dưới đây là các bước để một Developer mới clone dự án về và có thể chạy được ngay.

### 1. Yêu cầu hệ thống (Prerequisites)
- Môi trường Flutter SDK (phiên bản stable mới nhất).
- IDE: Android Studio, IntelliJ IDEA, hoặc Visual Studio Code.
- Cài đặt sẵn Firebase CLI (`npm install -g firebase-tools`).

### 2. Các bước cài đặt

**Bước 1:** Clone dự án về máy
```bash
git clone <repository_url>
cd fintech_app
```

**Bước 2:** Cài đặt các thư viện (Dependencies)
```bash
flutter pub get
```

**Bước 3:** Cấu hình Firebase
Vì dự án dùng Cloud Firestore và Firebase Auth, bạn cần liên kết dự án với một Firebase Project của riêng bạn:
1. Đăng nhập Firebase CLI: `firebase login`
2. Chạy cấu hình tự động của FlutterFire:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
3. *Lưu ý:* Chọn đúng project của bạn trên Firebase và làm theo luồng để sinh ra `firebase_options.dart` và các file `google-services.json` (Android) / `GoogleService-Info.plist` (iOS).

**Bước 4:** Cấu hình Gemini AI Key
1. Lấy API Key miễn phí tại Google AI Studio.
2. Chèn API key vào ứng dụng (tham khảo trong mã nguồn phần cấu hình key, thường nằm tại thư mục `core/constants/` hoặc file `.env`).

### 3. Chạy dự án
Kết nối thiết bị thật hoặc mở máy ảo (Android Emulator / iOS Simulator), sau đó chạy lệnh:
```bash
flutter run
```
