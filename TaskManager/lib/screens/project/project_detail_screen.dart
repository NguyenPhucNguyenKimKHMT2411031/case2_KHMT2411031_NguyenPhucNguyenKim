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
  int _unreadCount = 0;
  final _searchCtrl = TextEditingController();
  String _filterStatus = 'All', _filterPriority = 'All', _sortBy = 'createdAt';

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final pRes = await ApiService.getProjectById(widget.projectId);
    final tRes = await ApiService.getTasks(widget.projectId, search: _searchCtrl.text.trim(), status: _filterStatus, priority: _filterPriority, sortBy: _sortBy);
    final nRes = await ApiService.getNotifications();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (pRes['success'] == true) _project = pRes['data'];
      if (tRes['success'] == true) _tasks = tRes['data'] ?? [];
      if (nRes['success'] == true) _unreadCount = nRes['unreadCount'] ?? 0;
    });
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
      content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Email phụ trách chính', border: OutlineInputBorder())),
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
        DropdownButtonFormField<String>(value: p, items: const [DropdownMenuItem(value: 'view', child: Text('View')), DropdownMenuItem(value: 'edit', child: Text('Edit'))], onChanged: (v) => setS(() => p = v ?? 'view')),
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

  void _showAssignWithConfirmDialog(dynamic task) {
    final c = TextEditingController(); String p = 'edit';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Giao việc cho nhiều người'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c, decoration: const InputDecoration(labelText: 'Email (cách nhau dấu phẩy)', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: p, items: const [DropdownMenuItem(value: 'edit', child: Text('Edit')), DropdownMenuItem(value: 'view', child: Text('View'))], onChanged: (v) => setS(() => p = v ?? 'edit')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async {
          if (c.text.trim().isEmpty) return;
          final vRes = await ApiService.validateAssignEmails(task['_id'], c.text.trim(), p);
          if (!mounted || vRes['success'] != true) return;
          Navigator.pop(ctx);
          final valid = (vRes['data']['validUsers'] as List?) ?? [];
          final invalid = (vRes['data']['invalidEmails'] as List?) ?? [];
          showDialog(context: context, builder: (cCtx) => AlertDialog(
            title: const Text('Xác nhận giao việc'),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hợp lệ (${valid.length}):', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ...valid.map((u) => Text('• ${u['fullName']} (${u['email']})')),
              if (invalid.isNotEmpty) ...[const SizedBox(height: 8), Text('Bỏ qua: ${invalid.join(", ")}', style: const TextStyle(color: Colors.red))],
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(cCtx), child: const Text('Quay lại')),
              if (valid.isNotEmpty) ElevatedButton(onPressed: () async {
                Navigator.pop(cCtx);
                final r = await ApiService.assignTaskUsers(task['_id'], valid.map((u) => u['email']).join(','), p);
                if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? ''))); _loadData(); }
              }, child: Text('Xác nhận (${valid.length})')),
            ],
          ));
        }, child: const Text('Kiểm tra')),
      ],
    )));
  }
  Future<void> _showParticipantsDialog(String taskId, String taskTitle, bool canEdit) async {
    final res = await ApiService.getTaskParticipants(taskId);
    if (!mounted || res['success'] != true) return;
    final data = res['data']; final lead = data['leadAssignee'];
    final assignees = (data['assignees'] as List?) ?? []; final shared = (data['sharedWith'] as List?) ?? [];
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Danh sách: $taskTitle'),
      content: SizedBox(width: 400, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('★ Phụ trách chính: ${lead != null ? "${lead['fullName']} (${lead['email']})" : "Chưa có"}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const Divider(),
        ...assignees.map((a) => ListTile(dense: true, title: Text('Giao việc: ${a['user']?['fullName']} (${a['permission']})'), subtitle: Text(a['user']?['email'] ?? ''), trailing: canEdit ? IconButton(icon: const Icon(Icons.person_remove, color: Colors.red), onPressed: () async { Navigator.pop(ctx); await ApiService.removeTaskParticipant(taskId, a['user']['_id']); _loadData(); }) : null)),
        ...shared.map((s) => ListTile(dense: true, title: Text('Chia sẻ: ${s['user']?['fullName']} (${s['permission']})'), subtitle: Text(s['user']?['email'] ?? ''), trailing: canEdit ? IconButton(icon: const Icon(Icons.person_remove, color: Colors.red), onPressed: () async { Navigator.pop(ctx); await ApiService.removeTaskParticipant(taskId, s['user']['_id']); _loadData(); }) : null)),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
    ));
  }

  Future<void> _openNotificationsDialog() async {
    final res = await ApiService.getNotifications();
    if (!mounted || res['success'] != true) return;
    final list = (res['data'] as List?) ?? [];
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Thông báo (${res['unreadCount'] ?? 0} mới)'),
        TextButton(onPressed: () async { Navigator.pop(ctx); await ApiService.markAllNotificationsRead(); _loadData(); }, child: const Text('Đọc tất cả')),
      ]),
      content: SizedBox(width: 400, height: 320, child: list.isEmpty ? const Center(child: Text('Chưa có thông báo')) : ListView.builder(itemCount: list.length, itemBuilder: (_, i) {
        final n = list[i]; final read = n['isRead'] == true;
        return ListTile(leading: Icon(read ? Icons.notifications_none : Icons.notifications_active, color: read ? Colors.grey : Colors.blue), title: Text(n['title'] ?? '', style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold)), subtitle: Text(n['message'] ?? ''), onTap: () async { Navigator.pop(ctx); await ApiService.markNotificationRead(n['_id']); _loadData(); });
      })),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_project == null) return const Scaffold(body: Center(child: Text('Không tải được dự án')));
    return Scaffold(
      appBar: AppBar(title: Text(_project['name'] ?? 'Chi tiết dự án'), actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart),
          tooltip: 'Thống kê tiến độ dự án',
          onPressed: () async {
            final res = await ApiService.getProjectTaskStats(widget.projectId);
            if (!mounted || res['success'] != true) return;
            final d = res['data'];
            final int total = d['total'] ?? 0;
            final byS = d['byStatus'] ?? {};
            final byP = d['byPriority'] ?? {};
            final int done = byS['Done'] ?? 0;
            final double rate = total == 0 ? 0 : done / total;
            Widget bar(String label, int val, Color color) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$label: $val / $total'),
                const SizedBox(height: 2),
                LinearProgressIndicator(value: total == 0 ? 0 : val / total, color: color, minHeight: 8),
              ]),
            );
            showDialog(context: context, builder: (ctx) => AlertDialog(
              title: const Text('Thống kê công việc dự án'),
              content: SizedBox(width: 380, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tổng số việc: $total • Hoàn thành: ${(rate * 100).toStringAsFixed(0)}% • Quá hạn: ${d['overdue'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                const Text('Theo trạng thái:', style: TextStyle(fontWeight: FontWeight.bold)),
                bar('Todo', byS['Todo'] ?? 0, Colors.grey),
                bar('In-Progress', byS['In-Progress'] ?? 0, Colors.blue),
                bar('Done', done, Colors.green),
                const Divider(),
                const Text('Theo mức độ ưu tiên:', style: TextStyle(fontWeight: FontWeight.bold)),
                bar('High (Cao)', byP['High'] ?? 0, Colors.red),
                bar('Medium (Trung bình)', byP['Medium'] ?? 0, Colors.orange),
                bar('Low (Thấp)', byP['Low'] ?? 0, Colors.teal),
              ]))),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
            ));
          },
        ),
        IconButton(icon: const Icon(Icons.alarm), tooltip: 'Quét nhắc hạn', onPressed: () async { final r = await ApiService.checkDeadlines(); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? ''))); _loadData(); } }),
        IconButton(icon: Badge(isLabelVisible: _unreadCount > 0, label: Text('$_unreadCount'), child: const Icon(Icons.notifications)), onPressed: _openNotificationsDialog),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: _showCreateTaskDialog, icon: const Icon(Icons.add_task), label: const Text('Thêm việc')),
      body: Padding(padding: const EdgeInsets.all(16), child: ListView(children: [
        TextField(controller: _searchCtrl, decoration: InputDecoration(hintText: 'Tìm kiếm...', prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder()), onChanged: (_) => _loadData()),
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
          final canEdit = t['canEdit'] == true; final assignees = (t['assignees'] as List?) ?? []; final shared = (t['sharedWith'] as List?) ?? []; final lead = t['leadAssignee'];
          final due = t['dueDate'] != null ? DateTime.tryParse(t['dueDate'].toString()) : null;
          final isOverdue = t['status'] != 'Done' && due != null && due.isBefore(DateTime.now());
          final isUpcoming = t['status'] != 'Done' && due != null && !isOverdue && due.difference(DateTime.now()).inHours <= 24;
          return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Row(children: [Flexible(child: Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), const SizedBox(width: 8), Chip(label: Text(canEdit ? 'Chỉnh sửa' : 'Chỉ xem', style: const TextStyle(fontSize: 11)))])),
              DropdownButton<String>(value: t['status'] ?? 'Todo', items: ['Todo', 'In-Progress', 'Done'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: canEdit ? (v) async { if (v != null) { await ApiService.updateTaskStatus(t['_id'], v); _loadData(); } } : null),
            ]),
            Row(children: [
              Text('Ưu tiên: ${t['priority']} • Hạn: ${_fmtDate(t['dueDate'])}'),
              if (isOverdue) const Text(' [Quá hạn]', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              if (isUpcoming) const Text(' [Sắp đến hạn]', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Lịch sử'),
                onPressed: () async {
                  final res = await ApiService.getTaskActivities(t['_id']);
                  if (!mounted || res['success'] != true) return;
                  final logs = (res['data'] as List?) ?? [];
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                    title: Text('Lịch sử: ${t['title'] ?? ''}'),
                    content: SizedBox(width: 420, height: 320, child: logs.isEmpty
                      ? const Center(child: Text('Chưa có lịch sử hoạt động.'))
                      : ListView.separated(
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final l = logs[i];
                            final time = DateTime.tryParse(l['createdAt']?.toString() ?? '')?.toLocal();
                            final timeStr = time == null ? '' : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.day}/${time.month}/${time.year}';
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.bolt, size: 18, color: Colors.indigo),
                              title: Text('${l['action']} • ${l['actor']?['fullName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${l['detail'] ?? ''}\n$timeStr'),
                            );
                          },
                        )),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
                  ));
                },
              ),
              TextButton.icon(icon: const Icon(Icons.group, size: 16), label: Text('Danh sách (${assignees.length + shared.length})'), onPressed: () => _showParticipantsDialog(t['_id'], t['title'] ?? '', canEdit)),
              if (canEdit) TextButton(onPressed: () => _showLeadDialog(t), child: const Text('Phụ trách chính')),
              if (canEdit) TextButton(onPressed: () => _showShareDialog(t), child: const Text('Chia sẻ')),
            ]),
            Text(lead != null ? '★ Phụ trách chính: ${lead['fullName']}' : '★ Chưa có phụ trách chính', style: const TextStyle(fontSize: 13)),
            Row(children: [
              Expanded(child: Text('Giao: ${assignees.length} • Chia sẻ: ${shared.length}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey))),
              if (canEdit) TextButton(onPressed: () => _showAssignWithConfirmDialog(t), child: const Text('+ Giao việc')),
            ]),
          ])));
        }),
      ])),
    );
  }
}


