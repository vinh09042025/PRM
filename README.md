# WordSprint - Ứng dụng học từ vựng cá nhân hóa

WordSprint là một ứng dụng di động (và máy tính) giúp bạn học tập và ghi nhớ từ vựng một cách hiệu quả thông qua phương pháp Flashcard và Trắc nghiệm. Ứng dụng hoạt động hoàn toàn Offline, đảm bảo sự tập trung cao nhất.

## 🚀 Tính năng chính

- **Quản lý bộ thẻ:** Tạo các bộ từ vựng theo chủ đề riêng của bạn (IELTS, TOEIC, Giao tiếp...).
- **Học tập thông minh:**
    - **Flashcards:** Hiệu ứng lật thẻ 3D sinh động để ghi nhớ mặt chữ và nghĩa.
    - **Quiz:** Chế độ trắc nghiệm 4 đáp án giúp kiểm tra nhanh kiến thức.
- **Theo dõi tiến độ:** Hệ thống **Streak** giúp bạn duy trì thói quen học tập hàng ngày.
- **Dữ liệu Offline:** Toàn bộ dữ liệu được lưu trữ trực tiếp trên máy của bạn (SQLite).

## 🛠️ Yêu cầu hệ thống

- **Flutter SDK:** >= 3.0.0
- **Dart SDK:** >= 3.0.0
- **Nền tảng:** Android (minSdkVersion 21), Windows Desktop.

## 📥 Hướng dẫn cài đặt cho nhóm

Để bắt đầu làm việc với dự án này, vui lòng thực hiện các bước sau:

1.  **Clone dự án:**
    ```bash
    git clone https://github.com/vinh09042025/PRM.git
    cd PRM
    ```

2.  **Cài đặt thư viện:**
    ```bash
    flutter pub get
    ```

3.  **Lưu ý cho người dùng Windows:**
    Nếu bạn chạy trên Windows Desktop, hãy đảm bảo đã bật **Developer Mode** trong cài đặt hệ thống (Settings -> Update & Security -> For developers).

4.  **Chạy ứng dụng:**
    ```bash
    flutter run
    ```

## 📂 Cấu trúc thư mục chính

- `lib/models/`: Định nghĩa các thực thể dữ liệu (Deck, Word).
- `lib/data/`: Xử lý cơ sở dữ liệu SQLite.
- `lib/providers/`: Quản lý trạng thái và logic nghiệp vụ (Statemanagement).
- `lib/screens/`: Giao diện người dùng (Màn hình chính, học tập, trắc nghiệm).

## 🤝 Thành viên thực hiện
[Tên của nhóm bạn]

---
*Dự án được xây dựng với Material Design 3 và tông màu chủ đạo #7F77DD.*
