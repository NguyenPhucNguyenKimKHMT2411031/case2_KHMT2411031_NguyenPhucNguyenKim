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
  String _filterStatus = 'All', _filterPriority = 'All', _sortBy = 'createdAt';

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final pRes = await ApiService.getProjectById(widget.projectId);
    final tRes = await ApiService.getTasks(widget.projectId, search: _searchCtrl.text.trim(), status: _filterStatus, priority: _filterPriority, sortBy: _sortBy);
    if (!mounted) return;
    setState(() { _loading = false; if (pRes['success'] == true) _project = pRes['data']; if (tRes['success'] == true) _tasks = tRes['data'] ?? []; });
  }

  String _fmtDate(dynamic iso) {
    final d = iso == null ? null : DateTime.tryParse(iso.toString());
    return d == null ? 'Chưa đặt' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void _showCreateTaskDialog() {
    final titleCtrl = TextEditingController(), descCtrl = TextEditingController();
    String priority = 'Medium'; DateTime? startDate, dueDate;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Thêm công việc mới'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tên công việc *', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: priority, decoration: const InputDecoration(labelText: 'Ưu tiên', border: OutlineInputBorder()), items: ['Low', 'Medium', 'High'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setS(() => priority = v ?? 'Medium')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () async { final p = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030)); if (p != null) setS(() => startDate = p); }, child: Text(startDate == null ? 'Bắt đầu' : _fmtDate(startDate!.toIso8601String())))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: () async { final p = await showDatePicker(context: ctx, initialDate: startDate ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030)); if (p != null) setS(() => dueDate = p); }, child: Text(dueDate == null ? 'Hạn chót' : _fmtDate(dueDate!.toIso8601String())))),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async {
          if (titleCtrl.text.trim().isEmpty) return; Navigator.pop(ctx);
          final res = await ApiService.createTask({'projectId': widget.projectId, 'title': titleCtrl.text.trim(), 'description': descCtrl.text.trim(), 'priority': priority, 'startDate': startDate?.toIso8601String(), 'dueDate': dueDate?.toIso8601String()});
          if (mounted && res['success'] == true) _loadData();
        }, child: const Text('Tạo')),
      ],
    )));
  }

  void _showLeadDialog(dynamic task) {
    final c = TextEditingController(text: task['leadAssignee']?['email'] ?? '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Chỉ định phụ trách chính'),
      content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Email người phụ trách chính', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async {
          if (c.text.trim().isEmpty) return; Navigator.pop(ctx);
          final r = await ApiService.setTaskLead(task['_id'], c.text.trim());
          if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? ''))); if (r['success'] == true) _loadData(); }
        }, child: const Text('Xác nhận')),
      ],
    ));
  }

  void _showShareDialog(dynamic task) {
    final c = TextEditingController(); String p = 'view';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Chia sẻ công việc theo email'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c, decoration: const InputDecoration(labelText: 'Email người nhận', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: p, decoration: const InputDecoration(labelText: 'Quyền chia sẻ', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'view', child: Text('Chỉ xem (View)')), DropdownMenuItem(value: 'edit', child: Text('Chỉnh sửa (Edit)'))], onChanged: (v) => setS(() => p = v ?? 'view')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async {
          if (c.text.trim().isEmpty) return; Navigator.pop(ctx);
          final r = await ApiService.shareTask(task['_id'], c.text.trim(), p);
          if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? ''))); if (r['success'] == true) _loadData(); }
        }, child: const Text('Chia sẻ')),
      ],
    )));
  }

  Future<void> _showParticipantsDialog(String taskId, String taskTitle) async {
    final res = await ApiService.getTaskParticipants(taskId);
    if (!mounted || res['success'] != true) return;
    final data = res['data'];
    final lead = data['leadAssignee'];
    final assignees = (data['assignees'] as List?) ?? [];
    final shared = (data['sharedWith'] as List?) ?? [];
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Danh sách tham gia: $taskTitle'),
      content: SizedBox(width: 400, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('★ Phụ trách chính:', style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(dense: true, title: Text(lead != null ? '${lead['fullName']} (${lead['email']})' : 'Chưa chỉ định')),
        const Divider(),
        Text('Người được giao việc (${assignees.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
        if (assignees.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Chưa giao cho ai'))
        else ...assignees.map((a) => ListTile(dense: true, leading: const Icon(Icons.person), title: Text(a['user']?['fullName'] ?? ''), subtitle: Text(a['user']?['email'] ?? ''), trailing: Chip(label: Text(a['permission'] ?? 'edit')))),
        const Divider(),
        Text('Người được chia sẻ (${shared.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
        if (shared.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Chưa chia sẻ cho ai'))
        else ...shared.map((s) => ListTile(dense: true, leading: const Icon(Icons.share), title: Text(s['user']?['fullName'] ?? ''), subtitle: Text(s['user']?['email'] ?? ''), trailing: Chip(label: Text(s['permission'] ?? 'view')))),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
    ));
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_project == null) return const Scaffold(body: Center(child: Text('Không tải được dự án')));
    return Scaffold(
      appBar: AppBar(title: Text(_project['name'] ?? 'Chi tiết dự án')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _showCreateTaskDialog, icon: const Icon(Icons.add_task), label: const Text('Thêm việc')),
      body: Padding(padding: const EdgeInsets.all(16), child: ListView(children: [
        TextField(controller: _searchCtrl, decoration: InputDecoration(hintText: 'Tìm kiếm công việc...', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _loadData(); }), border: const OutlineInputBorder()), onChanged: (_) => _loadData()),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _filterStatus, decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()), items: ['All', 'Todo', 'In-Progress', 'Done'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { setState(() => _filterStatus = v ?? 'All'); _loadData(); })),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<String>(value: _filterPriority, decoration: const InputDecoration(labelText: 'Ưu tiên', border: OutlineInputBorder()), items: ['All', 'Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) { setState(() => _filterPriority = v ?? 'All'); _loadData(); })),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<String>(value: _sortBy, decoration: const InputDecoration(labelText: 'Sắp xếp', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'createdAt', child: Text('Mới nhất')), DropdownMenuItem(value: 'dueDate', child: Text('Hạn chót')), DropdownMenuItem(value: 'priority', child: Text('Ưu tiên'))], onChanged: (v) { setState(() => _sortBy = v ?? 'createdAt'); _loadData(); })),
        ]),
        const SizedBox(height: 12),
        ..._tasks.map((t) {
          final canEdit = t['canEdit'] == true;
          final assignees = (t['assignees'] as List?) ?? []; final shared = (t['sharedWith'] as List?) ?? []; final lead = t['leadAssignee'];
          return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Row(children: [
                Flexible(child: Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                const SizedBox(width: 8),
                Chip(label: Text(canEdit ? 'Quyền: Chỉnh sửa' : 'Quyền: Chỉ xem', style: const TextStyle(fontSize: 11)), backgroundColor: canEdit ? Colors.green.shade100 : Colors.grey.shade200),
              ])),
              DropdownButton<String>(value: t['status'] ?? 'Todo', items: ['Todo', 'In-Progress', 'Done'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: canEdit ? (v) async { if (v != null) { await ApiService.updateTaskStatus(t['_id'], v); _loadData(); } } : null),
            ]),
            Row(children: [
              Text('Ưu tiên: ${t['priority']} • Hạn: ${_fmtDate(t['dueDate'])}'),
              const Spacer(),
              TextButton.icon(icon: const Icon(Icons.group, size: 16), label: Text('Danh sách (${assignees.length + shared.length})'), onPressed: () => _showParticipantsDialog(t['_id'], t['title'] ?? '')),
              if (canEdit) TextButton(onPressed: () => _showLeadDialog(t), child: const Text('Phụ trách chính')),
              if (canEdit) TextButton(onPressed: () => _showShareDialog(t), child: const Text('Chia sẻ')),
            ]),
            Text(lead != null ? '★ Phụ trách chính: ${lead['fullName']} (${lead['email']})' : '★ Chưa có phụ trách chính', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Row(children: [
              Expanded(child: Text('Đã giao: ${assignees.isEmpty ? "Chưa có" : assignees.map((a) => "${a['user']?['fullName'] ?? ''} (${a['permission']})").join(", ")} | Chia sẻ: ${shared.isEmpty ? "Chưa có" : shared.map((s) => "${s['user']?['fullName'] ?? ''} (${s['permission']})").join(", ")}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey))),
              if (canEdit) TextButton(onPressed: () {
                final c = TextEditingController(); String p = 'edit';
                showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
                  title: const Text('Giao việc & Phân quyền'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(controller: c, decoration: const InputDecoration(labelText: 'Email (cách nhau dấu phẩy)', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(value: p, items: const [DropdownMenuItem(value: 'edit', child: Text('Edit')), DropdownMenuItem(value: 'view', child: Text('View'))], onChanged: (v) => setS(() => p = v ?? 'edit')),
                  ]),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')), ElevatedButton(onPressed: () async { Navigator.pop(ctx); final r = await ApiService.assignTaskUsers(t['_id'], c.text.trim(), p); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? ''))); _loadData(); } }, child: const Text('Giao'))],
                )));
              }, child: const Text('+ Giao việc')),
            ]),
          ])));
        }),
      ])),
    );
  }
}
