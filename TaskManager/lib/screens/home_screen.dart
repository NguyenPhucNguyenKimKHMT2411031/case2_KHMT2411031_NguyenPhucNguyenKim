import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'auth/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fullName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('user_name') ?? '';
      _email = prefs.getString('user_email') ?? '';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          IconButton(icon: const Icon(Icons.person), tooltip: 'Hồ sơ cá nhân', onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); _loadUser(); }),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Đăng xuất', onPressed: _logout),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Xin chào, $_fullName!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); _loadUser(); },
              icon: const Icon(Icons.edit),
              label: const Text('Xem & cập nhật hồ sơ'),
            ),
          ],
        ),
      ),
    );
  }
}
