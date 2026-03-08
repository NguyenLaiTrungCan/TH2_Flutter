import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todo_list/screens/home_screen.dart';
import 'package:todo_list/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

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
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.errorMessage(e));
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
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
    final welcomeName =
        AuthService.currentUser?.displayName ?? _nameCtrl.text.trim();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(welcomeName: welcomeName)),
      (route) => false,
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.register(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        displayName: _nameCtrl.text.trim(),
      );
      _goToHome();
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.errorMessage(e));
    } catch (e) {
      _showError('Đăng ký thất bại. Vui lòng thử lại.\n$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
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
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tên hiển thị
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập tên.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 16),

                  // Confirm password
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu.';
                      }
                      if (v != _passwordCtrl.text) {
                        return 'Mật khẩu không khớp.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Đăng ký
                  FilledButton(
                    onPressed: _loading ? null : _register,
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
                        : const Text('Đăng ký', style: TextStyle(fontSize: 16)),
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
                    onPressed: _loading ? null : _registerWithGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, _) =>
                          const Icon(Icons.login),
                    ),
                    label: const Text(
                      'Tiếp tục với Google',
                      style: TextStyle(fontSize: 15),
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

                  // Quay lại đăng nhập
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đã có tài khoản? ',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Đăng nhập'),
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
