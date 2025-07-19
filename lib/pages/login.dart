import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// ⚠️  BẮT BUỘC: dán Web client ID (OAuth 2.0) lấy trong Firebase Console
const String kServerClientId = '1030937736205-0cqdgdiojaqkggibddsd264vf28oqkmn.apps.googleusercontent.com';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtl = TextEditingController();
  final passCtl  = TextEditingController();
  bool isLoading = false;
  bool _didManualPress = false;     // biến cờ

  // Singleton phiên bản >=7.0
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSub;

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    await _googleSignIn.initialize(serverClientId: kServerClientId);
    _authSub = _googleSignIn.authenticationEvents
        .listen(_onGoogleAuthEvent, onError: _onGoogleAuthError);

    // Chỉ thử auto-login ở lần đầu khi chưa có user & chưa bấm nút
    if (FirebaseAuth.instance.currentUser == null && !_didManualPress) {
      _googleSignIn.attemptLightweightAuthentication();
    }
  }

  /// Xử lý event Google Sign-In thành công
  Future<void> _onGoogleAuthEvent(GoogleSignInAuthenticationEvent event) async {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      final account = event.user;
      try {
        final auth = await account.authentication;        // GoogleSignInAuthentication
        final credential = GoogleAuthProvider.credential(
          idToken: auth.idToken,                          // v7.x chỉ cần idToken
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      } catch (e) {
        _showError('Đăng nhập Google thất bại: $e');
      }
    }
  }

  void _onGoogleAuthError(Object error) {
    if (error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled) {
      // Người dùng tự hủy – im lặng bỏ qua
      return;
    }
    _showError('Google Sign-In lỗi: $error');
  }

  // Đăng nhập Email/Password
  Future<void> _loginWithEmail() async {
    final email = emailCtl.text.trim();
    final pass  = passCtl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _showError('Vui lòng nhập email và mật khẩu');
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
    } catch (e) {
      _showError('Đăng nhập thất bại: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Khi user bấm nút "Đăng nhập với Google"
  Future<void> _loginWithGoogle() async {
    _didManualPress = true;               // chặn auto-login lặp lại
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      await _googleSignIn.authenticate();
    } catch (e) {
      _onGoogleAuthError(e);
    } finally {
      if (mounted) setState(() => isLoading = false); // 3. kiểm tra mounted
    }
  }

// 3. ----- CHECK mounted bất cứ khi nào setState trong async -----
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    emailCtl.dispose();
    passCtl.dispose();
    _authSub?.cancel();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: emailCtl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextFormField(
              controller: passCtl,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton(
                onPressed: _loginWithEmail,
                child: const Text('Đăng nhập bằng Email'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Đăng nhập với Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: _loginWithGoogle,
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Chưa có tài khoản? Đăng ký'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                child: const Text('Quên mật khẩu?'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
