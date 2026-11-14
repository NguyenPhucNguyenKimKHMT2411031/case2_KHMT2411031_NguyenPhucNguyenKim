import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    final res = await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text);
    setState(() => _loading = false);

    if (!mounted) return;
    if (res['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res['token']);
      await prefs.setString('user_id', res['user']['id']);
      await prefs.setString('user_name', res['user']['fullName']);
      await prefs.setString('user_email', res['user']['email']);

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Lỗi đăng nhập')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Icon(Icons.task_alt, size: 72, color: Colors.blue),
            const SizedBox(height: 24),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _loading ? const CircularProgressIndicator() : const Text('Đăng nhập'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('Chưa có tài khoản? Đăng ký ngay'),
            ),
          ],
        ),
      ),
    );
  }
}
