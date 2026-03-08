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

2. Chạy (tại project root) với biến môi trường Firebase API key:

```bash
flutter pub get
flutter run \
  --dart-define=FIREBASE_WEB_API_KEY=YOUR_WEB_API_KEY \
  --dart-define=FIREBASE_ANDROID_API_KEY=YOUR_ANDROID_API_KEY \
  --dart-define=FIREBASE_IOS_API_KEY=YOUR_IOS_API_KEY \
  --dart-define=FIREBASE_MACOS_API_KEY=YOUR_MACOS_API_KEY \
  --dart-define=FIREBASE_WINDOWS_API_KEY=YOUR_WINDOWS_API_KEY
```

Bạn có thể tạo cấu hình Run trong VS Code để không phải nhập lại mỗi lần.

Ghi chú và lỗi thường gặp
- Nếu báo lỗi `Missing dart-define value for FIREBASE_*_API_KEY`, nghĩa là bạn chưa truyền đủ biến khi chạy/build.
- Nếu build Android báo lỗi về plugin google-services, kiểm tra file `android/app/google-services.json` có tồn tại và package name chính xác.
- Trên iOS, chạy `pod install` trong `ios/` nếu cần (`cd ios && pod install`).
- Bạn có thể dùng `flutterfire configure` để sinh các tệp cấu hình tự động cho nhiều môi trường.

Google Sign-In trên Windows
- Dự án đã hỗ trợ đăng nhập Google trên Windows qua `desktop_webview_auth`.
- Lần build đầu tiên trên Windows, plugin sẽ tải `nuget.exe` và các gói WebView2/WIL. Dòng `Nuget is not installed` và `Attempting to download nuget` chỉ là thông báo.
- Cần truyền thêm biến sau khi chạy:

```bash
flutter run -d windows --dart-define=FIREBASE_GOOGLE_DESKTOP_CLIENT_ID=YOUR_GOOGLE_OAUTH_CLIENT_ID
```

- `YOUR_GOOGLE_OAUTH_CLIENT_ID` phải là Google OAuth client có redirect URI:

```text
https://todolist-867ee.firebaseapp.com/__/auth/handler
```

- Nếu mạng chặn tải NuGet, hãy cài NuGet thủ công hoặc chạy lại build khi có internet.
- Cảnh báo `CMP0175` từ plugin hiện là cảnh báo CMake, không phải lỗi build chính.

Google Sign-In trên Android
- Nếu đăng nhập Google báo `PlatformException(sign_in_failed)` hoặc `ApiException: 10`, nguyên nhân gần như luôn là cấu hình OAuth Android chưa đúng.
- Dấu hiệu trong repo hiện tại: file `android/app/google-services.json` đang có `oauth_client: []`, nghĩa là Firebase chưa sinh OAuth client cho Android app.
- Cách sửa:
  1. Vào Firebase Console > Project settings > app Android `com.example.todo_list`.
  2. Thêm SHA-1 và SHA-256 của debug keystore và release keystore.
  3. Vào Authentication > Sign-in method, bật Google.
  4. Tải lại `google-services.json` mới và chép đè vào `android/app/google-services.json`.
  5. Chạy lại `flutter clean` rồi `flutter pub get`.

Bước 6 — Khi đã lộ key trên git
- Rotate (tạo mới) các Firebase API key trong Google Cloud Console.
- Áp giới hạn key theo app (Android package + SHA-1, iOS bundle id, HTTP referrer cho web nếu cần).
- Revoke key cũ và đánh dấu alert secret scanning trên GitHub là đã xử lý.

Nếu bạn muốn, tôi có thể:
- Chạy `flutter pub get` và kiểm tra build trên Android (yêu cầu bạn cho phép chạy lệnh),
- Hoặc cấu hình thêm `firebase_auth`, `firebase_analytics`, v.v., theo yêu cầu.
