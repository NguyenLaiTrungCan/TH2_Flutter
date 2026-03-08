import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/google.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:todo_list/firebase_options.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static const String _googleDesktopClientId = String.fromEnvironment(
    'FIREBASE_GOOGLE_DESKTOP_CLIENT_ID',
    defaultValue: '',
  );

  static bool get _usesNativeGoogleSignInPlugin {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  static bool get _usesDesktopGoogleSignIn {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  static bool get supportsGoogleSignIn {
    return kIsWeb || _usesNativeGoogleSignInPlugin || _usesDesktopGoogleSignIn;
  }

  static String get googleSignInUnsupportedMessage {
    return 'Đăng nhập Google hiện chưa được hỗ trợ trên nền tảng này. Hãy dùng email và mật khẩu, hoặc chạy ứng dụng trên Web, Android, iOS, macOS hay Windows.';
  }

  static bool get isGoogleDesktopClientConfigured {
    return _googleDesktopClientId.trim().isNotEmpty;
  }

  static String get googleDesktopClientConfigurationMessage {
    return 'Đăng nhập Google trên Windows cần cấu hình Google OAuth Client ID. Hãy chạy ứng dụng với --dart-define=FIREBASE_GOOGLE_DESKTOP_CLIENT_ID=YOUR_CLIENT_ID và bảo đảm redirect URI https://<auth-domain>/__/auth/handler đã được cấu hình.';
  }

  static String googleSignInErrorMessage(Object error) {
    if (error is PlatformException) {
      final rawMessage = [
        error.code,
        error.message,
        error.details?.toString(),
      ].whereType<String>().join(' ').toLowerCase();

      if (defaultTargetPlatform == TargetPlatform.android &&
          (rawMessage.contains('sign_in_failed') ||
              rawMessage.contains('apiexception: 10') ||
              rawMessage.contains('developer_error') ||
              rawMessage.contains('12500'))) {
        return 'Google Sign-In trên Android chưa được cấu hình đúng. Hãy thêm SHA-1 và SHA-256 cho app Android trong Firebase, bật Google trong Firebase Authentication, rồi tải lại file google-services.json mới nhất.';
      }

      return error.message ?? 'Đăng nhập Google thất bại.';
    }

    return error.toString();
  }

  static String? get googleSignInNotice {
    if (_usesDesktopGoogleSignIn && !isGoogleDesktopClientConfigured) {
      return googleDesktopClientConfigurationMessage;
    }
    if (!supportsGoogleSignIn) {
      return googleSignInUnsupportedMessage;
    }
    return null;
  }

  static String get _googleDesktopRedirectUri {
    final authDomain = DefaultFirebaseOptions.windows.authDomain;
    if (authDomain == null || authDomain.isEmpty) {
      throw UnsupportedError(
        'Thiếu authDomain trong cấu hình Firebase cho Windows.',
      );
    }
    return 'https://$authDomain/__/auth/handler';
  }

  /// Stream trạng thái đăng nhập
  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// User hiện tại (null nếu chưa đăng nhập)
  static User? get currentUser => _auth.currentUser;

  // ── Email / Password ─────────────────────────────────────────────────────

  /// Đăng ký bằng email và mật khẩu
  static Future<UserCredential> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (displayName != null && displayName.isNotEmpty) {
      await cred.user?.updateDisplayName(displayName);
      await cred.user?.reload();
    }

    final user = _auth.currentUser ?? cred.user;
    if (user != null) {
      await _safeSyncUserProfile(user, displayNameOverride: displayName);
    }

    return cred;
  }

  /// Đăng nhập bằng email và mật khẩu
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (cred.user != null) {
      await _safeSyncUserProfile(cred.user!);
    }

    return cred;
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────

  /// Đăng nhập bằng Google.
  /// Web: dùng signInWithPopup (mở cửa sổ popup, không reload trang).
  /// Mobile: dùng google_sign_in plugin.
  static Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      final cred = await _auth.signInWithPopup(provider);
      if (cred.user != null) {
        await _safeSyncUserProfile(cred.user!);
      }
      return cred;
    }

    if (_usesNativeGoogleSignInPlugin) {
      // Mobile: dùng google_sign_in
      await _googleSignIn.signOut().catchError((_) => null);
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // người dùng huỷ

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        await _safeSyncUserProfile(cred.user!);
      }
      return cred;
    }

    if (_usesDesktopGoogleSignIn) {
      if (!isGoogleDesktopClientConfigured) {
        throw UnsupportedError(googleDesktopClientConfigurationMessage);
      }

      final result = await DesktopWebviewAuth.signIn(
        GoogleSignInArgs(
          clientId: _googleDesktopClientId,
          redirectUri: _googleDesktopRedirectUri,
          scope: 'email profile openid',
        ),
      );

      if (result == null) {
        return null;
      }

      if (result.accessToken == null && result.idToken == null) {
        throw StateError('Không nhận được token Google hợp lệ.');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: result.accessToken,
        idToken: result.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        await _safeSyncUserProfile(cred.user!);
      }
      return cred;
    }

    throw UnsupportedError(googleSignInUnsupportedMessage);
  }

  /// Không còn cần thiết khi dùng signInWithPopup, giữ lại để tương thích.
  static Future<UserCredential?> getRedirectResult() async {
    return null;
  }

  static Future<void> _safeSyncUserProfile(
    User user, {
    String? displayNameOverride,
  }) async {
    try {
      await _syncUserProfile(user, displayNameOverride: displayNameOverride);
    } catch (error, stackTrace) {
      debugPrint('AuthService._syncUserProfile failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _syncUserProfile(
    User user, {
    String? displayNameOverride,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    final trimmedName = displayNameOverride?.trim();
    final providerIds = user.providerData
        .map((info) => info.providerId)
        .where((providerId) => providerId.isNotEmpty)
        .toList();

    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'displayName': (trimmedName != null && trimmedName.isNotEmpty)
          ? trimmedName
          : user.displayName,
      'photoUrl': user.photoURL,
      'providerIds': providerIds,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  // ── Sign out ─────────────────────────────────────────────────────────────

  /// Đăng xuất
  static Future<void> signOut() async {
    if (!kIsWeb && _usesNativeGoogleSignInPlugin) {
      await _googleSignIn.signOut().catchError((_) => null);
    }
    await _auth.signOut();
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  /// Chuyển mã lỗi Firebase Auth sang thông báo tiếng Việt
  static String errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email đã được sử dụng bởi tài khoản khác.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hoá.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng.';
      case 'account-exists-with-different-credential':
        return 'Email đã được dùng với phương thức đăng nhập khác.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được bật trong Firebase Authentication.';
      case 'configuration-not-found':
        return 'Cấu hình đăng nhập chưa đúng trong Firebase project.';
      case 'popup-blocked':
        return 'Trình duyệt đã chặn cửa sổ đăng nhập Google. Hãy cho phép popup và thử lại.';
      case 'popup-closed-by-user':
        return 'Bạn đã đóng cửa sổ đăng nhập Google.';
      case 'unauthorized-domain':
        return 'Domain hiện tại chưa được cho phép trong Firebase Authentication.';
      default:
        return e.message ?? 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
  }
}
