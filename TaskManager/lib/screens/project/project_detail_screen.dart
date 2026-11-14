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
  List<dynamic> _tasks = [];
  String _currentUserId = '';
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id') ?? '';
    final projRes = await ApiService.getProjectById(widget.projectId);
    final taskRes = await ApiService.getTasks(widget.projectId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (projRes['success'] == true) _project = projRes['data'];
      if (taskRes['success'] == true) _tasks = taskRes['data'] ?? [];
    });
  }

  bool get _isOwner => _project != null && _project['owner']?['_id'] == _currentUserId;

  void _showCreateTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Thêm công việc mới'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tên công việc *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async {
          if (titleCtrl.text.trim().isEmpty) return;
          Navigator.pop(ctx);
          final res = await ApiService.createTask({'projectId': widget.projectId, 'title': titleCtrl.text.trim(), 'description': descCtrl.text.trim()});
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
          if (res['success'] == true) _loadData();
        }, child: const Text('Tạo')),
      ],
    ));
  }

  Future<void> _changeStatus(String taskId, String newStatus) async {
    final res = await ApiService.updateTaskStatus(taskId, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
    if (res['success'] == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_project == null) return const Scaffold(body: Center(child: Text('Không tải được dự án')));
    return Scaffold(
      appBar: AppBar(title: Text(_project['name'] ?? 'Chi tiết dự án')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _showCreateTaskDialog, icon: const Icon(Icons.add_task), label: const Text('Thêm việc')),
      body: Padding(padding: const EdgeInsets.all(16), child: ListView(children: [
        Text('Danh sách công việc (${_tasks.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_tasks.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Chưa có công việc nào. Bấm "+ Thêm việc" để tạo!')))
        else ..._tasks.map((t) => Card(child: ListTile(
          title: Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(t['description'] ?? ''),
          trailing: DropdownButton<String>(
            value: t['status'] ?? 'Todo',
            items: ['Todo', 'In-Progress', 'Done'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) { if (val != null) _changeStatus(t['_id'], val); },
          ),
        ))),
      ])),
    );
  }
}
