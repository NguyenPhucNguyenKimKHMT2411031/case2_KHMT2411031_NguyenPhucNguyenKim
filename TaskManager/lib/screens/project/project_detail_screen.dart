import 'package:flutter/material.dart';
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
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final projRes = await ApiService.getProjectById(widget.projectId);
    final taskRes = await ApiService.getTasks(widget.projectId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (projRes['success'] == true) _project = projRes['data'];
      if (taskRes['success'] == true) _tasks = taskRes['data'] ?? [];
    });
  }

  void _showCreateTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'Medium';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) => AlertDialog(
      title: const Text('Thêm công việc mới'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tên công việc *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: priority,
          decoration: const InputDecoration(labelText: 'Mức độ ưu tiên', border: OutlineInputBorder()),
          items: ['Low', 'Medium', 'High'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setDlgState(() => priority = val ?? 'Medium'),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async {
          if (titleCtrl.text.trim().isEmpty) return;
          Navigator.pop(ctx);
          final res = await ApiService.createTask({'projectId': widget.projectId, 'title': titleCtrl.text.trim(), 'description': descCtrl.text.trim(), 'priority': priority});
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
          if (res['success'] == true) _loadData();
        }, child: const Text('Tạo')),
      ],
    )));
  }

  Future<void> _changeStatus(String taskId, String newStatus) async {
    final res = await ApiService.updateTaskStatus(taskId, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
    if (res['success'] == true) _loadData();
  }

  Future<void> _changePriority(String taskId, String newPriority) async {
    final res = await ApiService.updateTaskPriority(taskId, newPriority);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
    if (res['success'] == true) _loadData();
  }

  Color _priorityColor(String? p) {
    if (p == 'High') return Colors.red;
    if (p == 'Low') return Colors.green;
    return Colors.orange;
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
          subtitle: Row(children: [
            const Text('Ưu tiên: '),
            DropdownButton<String>(
              value: t['priority'] ?? 'Medium',
              underline: const SizedBox(),
              style: TextStyle(color: _priorityColor(t['priority']), fontWeight: FontWeight.bold),
              items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) { if (val != null) _changePriority(t['_id'], val); },
            ),
          ]),
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
