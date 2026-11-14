import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';
import '../widgets/task_history_dialog.dart'; // [E3] Import Dialog Lịch sử
import 'auth/login_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  // --- MODULE D1.4: Biến lưu số thông báo chưa đọc ---
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _fetchUnreadCount(); // Gọi lấy số lượng chưa đọc khi mở màn hình
  }

  // --- MODULE D1.4: Lấy số lượng thông báo chưa đọc ---
  Future<void> _fetchUnreadCount() async {
    try {
      final res = await ApiService.getUnreadNotificationCount();
      if (!mounted) return;
      if (res['success'] == true) {
        final data = res['data'];
        setState(() {
          if (data is Map && data.containsKey('count')) {
            _unreadCount = data['count'] ?? 0;
          } else if (data is int) {
            _unreadCount = data;
          } else if (data is Map && data['data'] is int) {
            _unreadCount = data['data'];
          }
        });
      }
    } catch (_) {}
  }

  // --- MODULE B: Lấy danh sách Task ---
  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getTasks();

      if (!mounted) return;

      if (res['success'] == true) {
        final rawData = res['data'];
        List taskList = [];

        if (rawData is List) {
          taskList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          taskList = rawData['data'];
        }

        setState(() {
          _tasks = taskList.map((json) => Task.fromJson(json)).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Lỗi tải danh sách task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải danh sách task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- MODULE B: Xóa Task ---
  Future<void> _deleteTask(String id) async {
    try {
      final res = await ApiService.deleteTask(id);

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa task thành công')),
        );
        _fetchTasks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Xóa task thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xóa task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- MODULE A: Đăng xuất ---
  Future<void> _handleLogout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  // --- MODULE D: Hộp thoại Thông báo (D1.1, D1.2, D1.3 & cập nhật D1.4) ---
  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thông báo (Module D)', style: TextStyle(fontSize: 18)),
              TextButton.icon(
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Đọc tất cả', style: TextStyle(fontSize: 12)),
                onPressed: () async {
                  final res = await ApiService.markAllAsRead();
                  if (dialogCtx.mounted) {
                    if (res['success'] == true) {
                      Navigator.pop(dialogCtx);
                      _fetchUnreadCount();
                      _showNotificationsDialog();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message']?.toString() ?? 'Lỗi cập nhật tất cả thông báo'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 300,
            child: FutureBuilder<dynamic>(
              future: ApiService.getNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return Center(child: Text('Lỗi: ${snapshot.error ?? "Không thể tải dữ liệu"}'));
                }

                final res = snapshot.data as Map<String, dynamic>;
                List notifications = [];

                if (res['success'] == true) {
                  if (res['data'] is List) {
                    notifications = res['data'];
                  } else if (res['data'] is Map && res['data']['notifications'] is List) {
                    notifications = res['data']['notifications'];
                  }
                }

                if (notifications.isEmpty) {
                  return const Center(child: Text('Không có thông báo nào'));
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index] as Map<String, dynamic>;
                    final bool isRead = item['isRead'] ?? false;
                    return ListTile(
                      leading: Icon(
                        isRead ? Icons.drafts : Icons.mark_email_unread,
                        color: isRead ? Colors.grey : Colors.blue,
                      ),
                      title: Text(item['title']?.toString() ?? item['message']?.toString() ?? 'Thông báo'),
                      subtitle: Text(item['message']?.toString() ?? item['createdAt']?.toString() ?? ''),
                      onTap: () async {
                        if (!isRead && item['_id'] != null) {
                          await ApiService.markAsRead(item['_id'].toString());
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                            _fetchUnreadCount();
                            _showNotificationsDialog();
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  // --- MODULE C: Hộp thoại Phân công Task ---
  void _showAssignDialog(Task task) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Phân công: ${task.title}'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email người nhận',
              hintText: 'nguoinhan@gmail.com',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(dialogCtx);

                try {
                  final res = await ApiService.shareTask(task.id, email, 'editor');

                  if (!mounted) return;
                  if (res['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã chia sẻ task cho $email')),
                    );
                    _fetchTasks();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message']?.toString() ?? 'Phân công thất bại'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi phân công: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Gán Task'),
            ),
          ],
        );
      },
    );
  }

  // --- MODULE B: Dialog Tạo / Cập nhật Task ---
  void _showTaskDialog({Task? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    String status = task?.status ?? 'pending';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(task == null ? 'Tạo Task mới' : 'Cập nhật Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tiêu đề'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: status,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Chờ xử lý (Pending)')),
                      DropdownMenuItem(value: 'in-progress', child: Text('Đang làm (In Progress)')),
                      DropdownMenuItem(value: 'completed', child: Text('Hoàn thành (Completed)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => status = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final desc = descController.text.trim();
                    if (title.isEmpty) return;

                    Navigator.pop(dialogCtx);
                    if (task == null) {
                      await _createTask(title, desc, status);
                    } else {
                      await _updateTask(task.id, title, desc, status);
                    }
                  },
                  child: Text(task == null ? 'Tạo' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- MODULE B: Tạo Task mới ---
  Future<void> _createTask(String title, String description, String status) async {
    try {
      final res = await ApiService.createTask({
        'title': title,
        'description': description,
        'status': status,
        'priority': 'medium',
        'type': 'personal',
      });

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo Task thành công!')),
        );
        await _fetchTasks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Tạo công việc thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tạo task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- MODULE B: Cập nhật Task ---
  Future<void> _updateTask(String id, String title, String description, String status) async {
    try {
      final res = await ApiService.updateTask(id, {
        'title': title,
        'description': description,
        'status': status,
      });

      if (!mounted) return;
      if (res['success'] == true) {
        _fetchTasks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Lỗi cập nhật task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Task'),
        actions: [
          // Icon Thông báo kèm Badge đếm số chưa đọc (Chức năng D1.4)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: 'Thông báo',
                onPressed: () {
                  _showNotificationsDialog();
                  _fetchUnreadCount();
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Icon Đăng xuất (Module A)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? const Center(child: Text('Chưa có task nào'))
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return ListTile(
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.status == 'completed'
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text('${task.description}\nTrạng thái: ${task.status}'),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Lịch sử hoạt động (Module E3)
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.purple),
                  tooltip: 'Xem lịch sử hoạt động',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => TaskHistoryDialog(
                        taskId: task.id,
                        taskTitle: task.title,
                      ),
                    );
                  },
                ),
                // Icon Phân công (Module C)
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.green),
                  tooltip: 'Phân công Task',
                  onPressed: () => _showAssignDialog(task),
                ),
                // Icon Sửa Task (Module B)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showTaskDialog(task: task),
                ),
                // Icon Xóa Task (Module B)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTask(task.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}