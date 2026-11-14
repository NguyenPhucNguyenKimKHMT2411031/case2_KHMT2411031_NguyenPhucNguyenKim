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
  final _searchCtrl = TextEditingController();
  String _filterStatus = 'All';
  String _filterPriority = 'All';

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final projRes = await ApiService.getProjectById(widget.projectId);
    final taskRes = await ApiService.getTasks(
      widget.projectId,
      search: _searchCtrl.text.trim(),
      status: _filterStatus,
      priority: _filterPriority,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (projRes['success'] == true) _project = projRes['data'];
      if (taskRes['success'] == true) _tasks = taskRes['data'] ?? [];
    });
  }

  String _fmtDate(dynamic iso) {
    if (iso == null) return 'Chưa đặt';
    final d = DateTime.tryParse(iso.toString());
    if (d == null) return 'Chưa đặt';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void _showCreateTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'Medium';
    DateTime? startDate;
    DateTime? dueDate;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) => AlertDialog(
      title: const Text('Thêm công việc mới'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
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
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(startDate == null ? 'Ngày bắt đầu' : _fmtDate(startDate!.toIso8601String())),
            onPressed: () async {
              final picked = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
              if (picked != null) setDlgState(() => startDate = picked);
            },
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.event, size: 16),
            label: Text(dueDate == null ? 'Hạn hoàn thành' : _fmtDate(dueDate!.toIso8601String())),
            onPressed: () async {
              final picked = await showDatePicker(context: ctx, initialDate: startDate ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
              if (picked != null) setDlgState(() => dueDate = picked);
            },
          )),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async {
          if (titleCtrl.text.trim().isEmpty) return;
          Navigator.pop(ctx);
          final res = await ApiService.createTask({
            'projectId': widget.projectId, 'title': titleCtrl.text.trim(), 'description': descCtrl.text.trim(),
            'priority': priority, 'startDate': startDate?.toIso8601String(), 'dueDate': dueDate?.toIso8601String()
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
          if (res['success'] == true) _loadData();
        }, child: const Text('Tạo')),
      ],
    )));
  }

  void _showEditDatesDialog(dynamic task) {
    DateTime? startDate = task['startDate'] != null ? DateTime.tryParse(task['startDate']) : null;
    DateTime? dueDate = task['dueDate'] != null ? DateTime.tryParse(task['dueDate']) : null;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) => AlertDialog(
      title: const Text('Thiết lập thời gian'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.calendar_today), title: Text('Bắt đầu: ${_fmtDate(startDate?.toIso8601String())}'), onTap: () async { final p = await showDatePicker(context: ctx, initialDate: startDate ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030)); if (p != null) setDlgState(() => startDate = p); }),
        ListTile(leading: const Icon(Icons.event), title: Text('Hạn chót: ${_fmtDate(dueDate?.toIso8601String())}'), onTap: () async { final p = await showDatePicker(context: ctx, initialDate: dueDate ?? startDate ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030)); if (p != null) setDlgState(() => dueDate = p); }),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          final res = await ApiService.updateTaskDates(task['_id'], startDate?.toIso8601String(), dueDate?.toIso8601String());
          if (mounted && res['success'] == true) _loadData();
        }, child: const Text('Lưu')),
      ],
    )));
  }

  Future<void> _changeStatus(String taskId, String newStatus) async {
    final res = await ApiService.updateTaskStatus(taskId, newStatus);
    if (mounted && res['success'] == true) _loadData();
  }

  Future<void> _changePriority(String taskId, String newPriority) async {
    final res = await ApiService.updateTaskPriority(taskId, newPriority);
    if (mounted && res['success'] == true) _loadData();
  }

  Color _priorityColor(String? p) => p == 'High' ? Colors.red : (p == 'Low' ? Colors.green : Colors.orange);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_project == null) return const Scaffold(body: Center(child: Text('Không tải được dự án')));
    return Scaffold(
      appBar: AppBar(title: Text(_project['name'] ?? 'Chi tiết dự án')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _showCreateTaskDialog, icon: const Icon(Icons.add_task), label: const Text('Thêm việc')),
      body: Padding(padding: const EdgeInsets.all(16), child: ListView(children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm công việc theo tên...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _loadData(); }),
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => _loadData(),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: _filterStatus,
            decoration: const InputDecoration(labelText: 'Lọc trạng thái', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: ['All', 'Todo', 'In-Progress', 'Done'].map((s) => DropdownMenuItem(value: s, child: Text(s == 'All' ? 'Tất cả trạng thái' : s))).toList(),
            onChanged: (val) { setState(() => _filterStatus = val ?? 'All'); _loadData(); },
          )),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(
            value: _filterPriority,
            decoration: const InputDecoration(labelText: 'Lọc ưu tiên', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: ['All', 'Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p == 'All' ? 'Tất cả ưu tiên' : p))).toList(),
            onChanged: (val) { setState(() => _filterPriority = val ?? 'All'); _loadData(); },
          )),
        ]),
        const SizedBox(height: 14),
        Text('Danh sách công việc (${_tasks.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_tasks.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Không tìm thấy công việc phù hợp.')))
        else ..._tasks.map((t) => Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            DropdownButton<String>(value: t['status'] ?? 'Todo', items: ['Todo', 'In-Progress', 'Done'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (val) { if (val != null) _changeStatus(t['_id'], val); }),
          ]),
          Row(children: [
            const Text('Ưu tiên: '),
            DropdownButton<String>(value: t['priority'] ?? 'Medium', underline: const SizedBox(), style: TextStyle(color: _priorityColor(t['priority']), fontWeight: FontWeight.bold), items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (val) { if (val != null) _changePriority(t['_id'], val); }),
            const Spacer(),
            TextButton.icon(icon: const Icon(Icons.date_range, size: 16), label: Text('${_fmtDate(t['startDate'])} → ${_fmtDate(t['dueDate'])}'), onPressed: () => _showEditDatesDialog(t)),
          ]),
        ])))),
      ])),
    );
  }
}
