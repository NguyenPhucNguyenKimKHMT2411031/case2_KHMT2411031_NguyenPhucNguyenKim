import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});
  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  dynamic _project;
  String _currentUserId = '';
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadProject(); }

  Future<void> _loadProject() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id') ?? '';
    final res = await ApiService.getProjectById(widget.projectId);
    if (!mounted) return;
    setState(() { _loading = false; if (res['success'] == true) _project = res['data']; });
  }

  bool get _isOwner => _project != null && _project['owner']?['_id'] == _currentUserId;

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: _project['name']);
    final descCtrl = TextEditingController(text: _project['description']);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Chỉnh sửa dự án'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên dự án', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          final res = await ApiService.updateProject(widget.projectId, nameCtrl.text.trim(), descCtrl.text.trim());
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
          if (res['success'] == true) _loadProject();
        }, child: const Text('Lưu')),
      ],
    ));
  }

  Future<void> _deleteProject() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Xác nhận xóa'), content: const Text('Bạn có chắc chắn muốn xóa dự án này không?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
      ],
    ));
    if (confirm != true) return;
    final res = await ApiService.deleteProject(widget.projectId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
    if (res['success'] == true) Navigator.pop(context, true);
  }

  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Mời thành viên'),
      content: TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Nhập Email thành viên', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async {
          if (emailCtrl.text.trim().isEmpty) return;
          Navigator.pop(ctx);
          final res = await ApiService.addMember(widget.projectId, emailCtrl.text.trim());
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
          if (res['success'] == true) _loadProject();
        }, child: const Text('Mời')),
      ],
    ));
  }

  Future<void> _removeMember(String memberId) async {
    final res = await ApiService.removeMember(widget.projectId, memberId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
    if (res['success'] == true) _loadProject();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_project == null) return const Scaffold(body: Center(child: Text('Không tải được dự án')));
    final members = (_project['members'] as List?) ?? [];
    final ownerId = _project['owner']?['_id'];
    return Scaffold(
      appBar: AppBar(title: Text(_project['name'] ?? 'Chi tiết dự án'), actions: [
        if (_isOwner) ...[
          IconButton(icon: const Icon(Icons.edit), tooltip: 'Sửa dự án', onPressed: _showEditDialog),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), tooltip: 'Xóa dự án', onPressed: _deleteProject),
        ]
      ]),
      body: Padding(padding: const EdgeInsets.all(16), child: ListView(children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mô tả dự án', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text((_project['description'] ?? '').isNotEmpty ? _project['description'] : 'Chưa có mô tả'),
        ]))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Thành viên (${members.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_isOwner) ElevatedButton.icon(onPressed: _showInviteDialog, icon: const Icon(Icons.person_add), label: const Text('Mời')),
        ]),
        const SizedBox(height: 8),
        ...members.map((m) {
          final isProjectOwner = m['_id'] == ownerId;
          return Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(m['fullName'] ?? ''), subtitle: Text(m['email'] ?? ''),
            trailing: isProjectOwner ? const Chip(label: Text('Chủ dự án')) : (_isOwner ? IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _removeMember(m['_id'])) : null),
          ));
        }),
      ])),
    );
  }
}
