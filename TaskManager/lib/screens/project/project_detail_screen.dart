import 'package:flutter/material.dart';
import 'package:task_manager/services/api_service.dart';

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
  String _roleTab = 'Tất cả';
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

  List<dynamic> get _filteredTasks {
    if (_roleTab == 'Tất cả') return _tasks;
    if (_roleTab == 'Của tôi') return _tasks.where((t) => t['canEdit'] == true && ((t['assignees'] as List?)?.isEmpty ?? true)).toList();
    if (_roleTab == 'Được giao') return _tasks.where((t) => ((t['assignees'] as List?)?.isNotEmpty ?? false) || t['leadAssignee'] != null).toList();
    if (_roleTab == 'Được chia sẻ') return _tasks.where((t) => (t['sharedWith'] as List?)?.isNotEmpty ?? false).toList();
    return _tasks;
  }

  String _fmtDate(dynamic iso) {
    final d = iso == null ? null : DateTime.tryParse(iso.toString());
    return d == null ? '' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _statusVi(String? s) => s == 'In-Progress' ? 'Đang thực hiện' : s == 'Done' ? 'Hoàn thành' : 'Chưa thực hiện';
  Color _statusColor(String? s) => s == 'In-Progress' ? Colors.blue : s == 'Done' ? Colors.green : Colors.grey;

  void _showCreateTaskDialog() {
    final titleCtrl = TextEditingController(), descCtrl = TextEditingController();
    String priority = 'Medium'; DateTime? dueDate;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Thêm công việc mới'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tên công việc *', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: priority, decoration: const InputDecoration(labelText: 'Ưu tiên', border: OutlineInputBorder()), items: ['Low', 'Medium', 'High'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setS(() => priority = v ?? 'Medium')),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: () async { final p = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030)); if (p != null) setS(() => dueDate = p); }, child: Text(dueDate == null ? 'Chọn hạn chót' : 'Hạn: ${_fmtDate(dueDate!.toIso8601String())}')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async {
          if (titleCtrl.text.trim().isEmpty) return; Navigator.pop(ctx);
          await ApiService.createTask({'projectId': widget.projectId, 'title': titleCtrl.text.trim(), 'description': descCtrl.text.trim(), 'priority': priority, 'dueDate': dueDate?.toIso8601String()});
          if (mounted) _loadData();
        }, child: const Text('Tạo')),
      ],
    )));
  }
  void _showFilterSheet() {
    showModalBottomSheet(context: context, builder: (ctx) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Lọc công việc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _filterStatus, decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()), items: ['All', 'Todo', 'In-Progress', 'Done'].map((s) => DropdownMenuItem(value: s, child: Text(s == 'All' ? 'Tất cả trạng thái' : _statusVi(s)))).toList(), onChanged: (v) { setState(() => _filterStatus = v ?? 'All'); _loadData(); Navigator.pop(ctx); }),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: _filterPriority, decoration: const InputDecoration(labelText: 'Ưu tiên', border: OutlineInputBorder()), items: ['All', 'Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p == 'All' ? 'Tất cả ưu tiên' : p))).toList(), onChanged: (v) { setState(() => _filterPriority = v ?? 'All'); _loadData(); Navigator.pop(ctx); }),
    ])));
  }

  void _showSortSheet() {
    showModalBottomSheet(context: context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
      const ListTile(title: Text('Sắp xếp theo', style: TextStyle(fontWeight: FontWeight.bold))),
      ListTile(title: const Text('Mới nhất'), selected: _sortBy == 'createdAt', onTap: () { setState(() => _sortBy = 'createdAt'); _loadData(); Navigator.pop(ctx); }),
      ListTile(title: const Text('Hạn chót gần nhất'), selected: _sortBy == 'dueDate', onTap: () { setState(() => _sortBy = 'dueDate'); _loadData(); Navigator.pop(ctx); }),
      ListTile(title: const Text('Mức độ ưu tiên'), selected: _sortBy == 'priority', onTap: () { setState(() => _sortBy = 'priority'); _loadData(); Navigator.pop(ctx); }),
    ]));
  }

  void _showSimpleEmailDialog(String title, String btnText, bool hasPerm, Future<dynamic> Function(String, String) onSubmit) {
    final c = TextEditingController(); String p = 'edit';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c, decoration: const InputDecoration(labelText: 'Nhập email', border: OutlineInputBorder())),
        if (hasPerm) ...[const SizedBox(height: 10), DropdownButtonFormField<String>(value: p, items: const [DropdownMenuItem(value: 'edit', child: Text('Chỉnh sửa (Edit)')), DropdownMenuItem(value: 'view', child: Text('Chỉ xem (View)'))], onChanged: (v) => setS(() => p = v ?? 'edit'))],
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async { if (c.text.trim().isEmpty) return; Navigator.pop(ctx); final r = await onSubmit(c.text.trim(), p); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? ''))); _loadData(); } }, child: Text(btnText)),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final items = _filteredTasks;
    final tabs = ['Tất cả', 'Của tôi', 'Được giao', 'Được chia sẻ'];
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F5F8),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: const Text('Công việc của tôi', style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart, color: Colors.black54), tooltip: 'Thống kê', onPressed: () async {
            final res = await ApiService.getProjectStats(widget.projectId);
            if (!mounted || res['success'] != true) return;
            final d = res['data'];
            showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Thống kê dự án'), content: Text('Tổng việc: ${d['total']}\nChưa làm: ${d['byStatus']['Todo']} | Đang làm: ${d['byStatus']['In-Progress']} | Xong: ${d['byStatus']['Done']}\nQuá hạn: ${d['overdue']}'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))]));
          }),
          IconButton(icon: const Icon(Icons.alarm, color: Colors.black54), tooltip: 'Quét nhắc hạn', onPressed: () async { final r = await ApiService.checkDeadlines(); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? ''))); _loadData(); } }),
          IconButton(icon: Badge(isLabelVisible: _unreadCount > 0, label: Text('$_unreadCount'), child: const Icon(Icons.notifications_none, color: Colors.black54)), onPressed: () async {
            final res = await ApiService.getNotifications();
            if (!mounted || res['success'] != true) return;
            final list = (res['data'] as List?) ?? [];
            showDialog(context: context, builder: (ctx) => AlertDialog(
              title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Thông báo (${res['unreadCount'] ?? 0})'), TextButton(onPressed: () async { Navigator.pop(ctx); await ApiService.markAllNotificationsRead(); _loadData(); }, child: const Text('Đọc tất cả'))]),
              content: SizedBox(width: 380, height: 280, child: list.isEmpty ? const Center(child: Text('Chưa có thông báo')) : ListView.builder(itemCount: list.length, itemBuilder: (_, i) => ListTile(title: Text(list[i]['title'] ?? ''), subtitle: Text(list[i]['message'] ?? '')))),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
            ));
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showCreateTaskDialog, backgroundColor: const Color(0xFFE8DEF8), child: const Icon(Icons.add, color: Color(0xFF1D192B))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _loadData(),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm công việc theo tên...',
              hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              filled: true,
              fillColor: const Color(0xFFECEAF0),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            ...tabs.map((tab) {
              final selected = _roleTab == tab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (selected) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.check, size: 16, color: Color(0xFF4A4458))),
                    Text(tab, style: TextStyle(fontSize: 13, color: selected ? const Color(0xFF1D192B) : Colors.black87, fontWeight: selected ? FontWeight.w500 : FontWeight.normal)),
                  ]),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: const Color(0xFFE8DEF8),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: selected ? Colors.transparent : Colors.black26)),
                  onSelected: (_) => setState(() => _roleTab = tab),
                ),
              );
            }),
            Padding(padding: const EdgeInsets.only(right: 8), child: OutlinedButton.icon(icon: const Icon(Icons.filter_list, size: 16, color: Colors.black87), label: const Text('Lọc', style: TextStyle(fontSize: 13, color: Colors.black87)), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: const BorderSide(color: Colors.black26)), onPressed: _showFilterSheet)),
            OutlinedButton.icon(icon: const Icon(Icons.sort, size: 16, color: Colors.black87), label: const Text('Sắp xếp', style: TextStyle(fontSize: 13, color: Colors.black87)), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: const BorderSide(color: Colors.black26)), onPressed: _showSortSheet),
          ]),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Colors.black12),
        Expanded(
          child: items.isEmpty
            ? const Center(child: Text('Chưa có công việc nào', style: TextStyle(color: Colors.black45)))
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                itemBuilder: (_, i) {
                  final t = items[i];
                  final canEdit = t['canEdit'] == true;
                  final status = t['status'] ?? 'Todo';
                  final desc = (t['description'] ?? '').toString().trim();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t['title'] ?? '', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                        if (desc.isNotEmpty) ...[const SizedBox(height: 3), Text(desc, style: const TextStyle(fontSize: 13.5, color: Colors.black54))],
                        const SizedBox(height: 6),
                        Row(children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(_statusVi(status), style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                          if (t['leadAssignee'] != null) Text('  •  Phụ trách: ${t['leadAssignee']['fullName']}', style: const TextStyle(fontSize: 12.5, color: Colors.black45)),
                        ]),
                      ])),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.black45, size: 20),
                        onSelected: (val) async {
                          if (val == 'status') { final next = status == 'Todo' ? 'In-Progress' : status == 'In-Progress' ? 'Done' : 'Todo'; await ApiService.updateTaskStatus(t['_id'], next); _loadData(); }
                          else if (val == 'assign') _showSimpleEmailDialog('Giao việc', 'Giao việc', true, (e, p) => ApiService.assignTaskUsers(t['_id'], e, p));
                          else if (val == 'lead') _showSimpleEmailDialog('Chỉ định phụ trách chính', 'Xác nhận', false, (e, _) => ApiService.setLeadAssignee(t['_id'], e));
                          else if (val == 'share') _showSimpleEmailDialog('Chia sẻ công việc', 'Chia sẻ', true, (e, p) => ApiService.shareTask(t['_id'], e, p));
                          else if (val == 'history') {
                            final res = await ApiService.getTaskActivities(t['_id']);
                            if (!mounted || res['success'] != true) return;
                            final logs = (res['data'] as List?) ?? [];
                            showDialog(context: context, builder: (ctx) => AlertDialog(title: Text('Lịch sử: ${t['title']}'), content: SizedBox(width: 380, height: 280, child: ListView.builder(itemCount: logs.length, itemBuilder: (_, idx) => ListTile(dense: true, title: Text('${logs[idx]['action']} • ${logs[idx]['actor']?['fullName'] ?? ''}'), subtitle: Text(logs[idx]['detail'] ?? '')))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))]));
                          }
                        },
                        itemBuilder: (_) => [
                          if (canEdit) const PopupMenuItem(value: 'status', child: Text('Đổi trạng thái')),
                          if (canEdit) const PopupMenuItem(value: 'assign', child: Text('Giao việc')),
                          if (canEdit) const PopupMenuItem(value: 'lead', child: Text('Chỉ định phụ trách chính')),
                          if (canEdit) const PopupMenuItem(value: 'share', child: Text('Chia sẻ')),
                          const PopupMenuItem(value: 'history', child: Text('Lịch sử hoạt động')),
                        ],
                      ),
                    ]),
                  );
                },
              ),
        ),
      ]),
    );
  }
}
