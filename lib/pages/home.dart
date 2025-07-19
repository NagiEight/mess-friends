import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang Chủ"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: Center(
        child: Text('Xin chào, ${user?.email ?? 'User'}!'),
      ),
    );
  }
}
Future<void> logout() async {
  // Ngắt liên kết với Google ở thiết bị
  await GoogleSignIn.instance.disconnect(); // hoặc signOut()
  // Đăng xuất Firebase
  await FirebaseAuth.instance.signOut();
}