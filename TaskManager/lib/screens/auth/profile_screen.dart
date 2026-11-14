import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  String _email = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (res['success'] == true) {
          _nameCtrl.text = res['data']['fullName'] ?? '';
          _avatarCtrl.text = res['data']['avatarUrl'] ?? '';
          _email = res['data']['email'] ?? '';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.updateProfile(_nameCtrl.text.trim(), _avatarCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _nameCtrl.text.trim());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 42,
                      backgroundImage: _avatarCtrl.text.isNotEmpty ? NetworkImage(_avatarCtrl.text) : null,
                      child: _avatarCtrl.text.isEmpty ? const Icon(Icons.person, size: 42) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Email: $_email', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _avatarCtrl, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Link ảnh đại diện (Avatar URL)', border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: _saving ? const CircularProgressIndicator() : const Text('Lưu thay đổi'),
                  ),
                ],
              ),
            ),
    );
  }
}
