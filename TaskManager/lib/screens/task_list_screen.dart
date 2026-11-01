import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../services/api_service.dart';
import 'auth/login_screen.dart';
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/tasks'),
        headers: headers,
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _tasks = data.map((json) => Task.fromJson(json)).toList();
        });
      } else if (res.statusCode == 401) {
        _handleLogout();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách task: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/tasks/$id'),
        headers: headers,
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa task thành công')),
        );
        _fetchTasks();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xóa task: $e')),
      );
    }
  }

  Future<void> _handleLogout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

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

  Future<void> _createTask(String title, String description, String status) async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/tasks'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'status': status,
        }),
      );

      if (!mounted) return;
      if (res.statusCode == 201) {
        _fetchTasks();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo task: $e')),
      );
    }
  }

  Future<void> _updateTask(String id, String title, String description, String status) async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http.put(
        Uri.parse('${ApiService.baseUrl}/tasks/$id'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'status': status,
        }),
      );

      if (!mounted) return;
      if (res.statusCode == 200) {
        _fetchTasks();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật task: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showTaskDialog(task: task),
                ),
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