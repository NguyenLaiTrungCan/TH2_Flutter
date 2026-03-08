import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_list/screens/home_screen.dart';
import 'package:todo_list/services/auth_service.dart';
import 'package:todo_list/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // Sau khi Google redirect quay lại app, kiểm tra kết quả / lỗi
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkRedirectResult(),
      );
    }
  }

  /// Kiểm tra kết quả redirect của Google Sign-In (web only).
  Future<void> _checkRedirectResult() async {
    try {
      await AuthService.getRedirectResult();
      // Nếu thành công, authStateChanges ở main.dart tự động chuyển sang HomeScreen.
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.errorMessage(e));
    } catch (_) {
      // bỏ qua lỗi không quan trọng (ví dụ không có redirect pending)
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      _goToHome();
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.errorMessage(e));
    } catch (_) {
      _showError('Đăng nhập thất bại. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      if (!AuthService.supportsGoogleSignIn) {
        _showError(AuthService.googleSignInUnsupportedMessage);
        return;
      }

      // Dùng signInWithPopup: mở cửa sổ popup, không reload trang.
      // authStateChanges sẽ tự chuyển sang HomeScreen sau khi đăng nhập thành công.
      final credential = await AuthService.signInWithGoogle();
      if (credential?.user != null) {
        _goToHome();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code != 'popup_closed_by_user' &&
          e.code != 'cancelled_popup_request') {
        _showError(AuthService.errorMessage(e));
      }
    } on PlatformException catch (e) {
      _showError(AuthService.googleSignInErrorMessage(e));
    } on UnsupportedError catch (e) {
      _showError(e.message ?? AuthService.googleSignInUnsupportedMessage);
    } catch (e) {
      _showError('Đăng nhập Google thất bại: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final googleSignInNotice = AuthService.googleSignInNotice;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / tiêu đề
                  Icon(Icons.note_alt_rounded, size: 72, color: cs.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Smart Note',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đăng nhập để tiếp tục',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập email.';
                      }
                      if (!v.contains('@')) {
                        return 'Email không hợp lệ.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Vui lòng nhập mật khẩu.';
                      }
                      if (v.length < 6) {
                        return 'Mật khẩu tối thiểu 6 ký tự.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Đăng nhập
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Đăng nhập',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'hoặc',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: _loading && kIsWeb
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, _) =>
                                const Icon(Icons.login),
                          ),
                    label: Text(
                      _loading && kIsWeb
                          ? 'Đang chuyển hướng tới Google...'
                          : 'Đăng nhập bằng Google',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  if (googleSignInNotice != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      googleSignInNotice,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Chuyển sang đăng ký
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản? ',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                        child: const Text('Đăng ký'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
