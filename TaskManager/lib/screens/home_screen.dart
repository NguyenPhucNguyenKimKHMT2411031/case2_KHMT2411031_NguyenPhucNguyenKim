import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'auth/login_screen.dart';
import 'auth/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fullName = '';
  List<dynamic> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _fullName = prefs.getString('user_name') ?? '');
    try {
      final res = await ApiService.getProjects();
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (res['success'] == true) _projects = res['data'] ?? [];
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _showCreateProjectDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo dự án mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên dự án *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Mô tả ngắn', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final res = await ApiService.createProject(nameCtrl.text.trim(), descCtrl.text.trim());
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
              if (res['success'] == true) _loadData();
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dự án của $_fullName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Hồ sơ cá nhân',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              _loadData();
            },
          ),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Đăng xuất', onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProjectDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tạo dự án'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? const Center(child: Text('Chưa có dự án nào. Bấm "+ Tạo dự án" để bắt đầu!'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      final p = _projects[index];
                      final memberCount = (p['members'] as List?)?.length ?? 1;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.folder)),
                          title: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text((p['description'] ?? '').isNotEmpty ? p['description'] : 'Không có mô tả'),
                          trailing: Chip(label: Text('$memberCount thành viên')),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
