Hướng dẫn cài đặt và cấu hình Firebase cho dự án Flutter `todo_list`

Bước 1 — Tạo project Firebase
- Truy cập https://console.firebase.google.com và tạo một project mới.

Bước 2 — Thêm Android app
- Package name (Android): `com.example.todo_list` (đảm bảo khớp với `android/app/...`)
- Đăng ký app, rồi tải về `google-services.json`.
- Đặt file `google-services.json` vào: `android/app/google-services.json`.

Bước 3 — Thêm iOS app (nếu cần)
- Bundle ID iOS: mở `ios/Runner.xcodeproj` để kiểm tra (thường giống `com.example.todo_list`).
- Tải `GoogleService-Info.plist` và kéo vào Xcode Runner target (hoặc đặt vào `ios/Runner/` và thêm vào Xcode project).

Bước 4 — Đã thực hiện trong repo (tự động)
- Thêm dependencies vào `pubspec.yaml`:
  - `firebase_core: ^2.6.1`
  - `cloud_firestore: ^4.9.0`
- Khởi tạo Firebase trong `lib/main.dart` gọi `Firebase.initializeApp()` trước `runApp()`.
- Đã thêm `com.google.gms:google-services:4.3.15` vào `android/build.gradle.kts` và áp dụng plugin trong `android/app/build.gradle.kts`.

Bước 5 — Cài đặt và chạy
1. Cài FlutterFire CLI (tùy chọn, hữu ích để cấu hình tự động):

```bash
dart pub global activate flutterfire_cli
```

2. Chạy (tại project root):

```bash
flutter pub get
flutter run
```

Ghi chú và lỗi thường gặp
- Nếu build Android báo lỗi về plugin google-services, kiểm tra file `android/app/google-services.json` có tồn tại và package name chính xác.
- Trên iOS, chạy `pod install` trong `ios/` nếu cần (`cd ios && pod install`).
- Bạn có thể dùng `flutterfire configure` để sinh các tệp cấu hình tự động cho nhiều môi trường.

Nếu bạn muốn, tôi có thể:
- Chạy `flutter pub get` và kiểm tra build trên Android (yêu cầu bạn cho phép chạy lệnh),
- Hoặc cấu hình thêm `firebase_auth`, `firebase_analytics`, v.v., theo yêu cầu.
