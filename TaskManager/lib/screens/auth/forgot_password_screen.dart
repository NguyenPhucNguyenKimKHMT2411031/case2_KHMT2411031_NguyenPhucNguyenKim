import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;

  Future<void> _sendOtp() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.forgotPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
      if (res['success'] == true) {
        setState(() {
          _otpSent = true;
          if (res['devOtp'] != null) _otpCtrl.text = res['devOtp'].toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPass() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.resetPassword(_emailCtrl.text.trim(), _otpCtrl.text.trim(), _newPassCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
      if (res['success'] == true) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: _emailCtrl, enabled: !_otpSent, decoration: const InputDecoration(labelText: 'Email đã đăng ký', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            if (!_otpSent)
              ElevatedButton(
                onPressed: _loading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: _loading ? const CircularProgressIndicator() : const Text('Gửi mã OTP'),
              )
            else ...[
              TextField(controller: _otpCtrl, decoration: const InputDecoration(labelText: 'Mã OTP (6 chữ số)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu mới', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _resetPass,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: _loading ? const CircularProgressIndicator() : const Text('Đặt lại mật khẩu'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
