import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Map<String, dynamic>? _summary;
  List<dynamic> _userPerformance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    final summaryRes = await ApiService.getTaskSummary();
    final perfRes = await ApiService.getUserPerformance();

    if (mounted) {
      setState(() {
        if (summaryRes['success']) _summary = summaryRes['data'];
        if (perfRes['success']) _userPerformance = perfRes['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê (Reports)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Thống kê tổng quan (E1.1)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_summary != null)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard('Tổng số công việc', '${_summary!['totalTasks']}', Colors.blue),
                  _buildStatCard('Đã hoàn thành', '${_summary!['completedTasks']}', Colors.green),
                  _buildStatCard('Đang thực hiện', '${_summary!['inProgressTasks']}', Colors.orange),
                  _buildStatCard('Đang chờ', '${_summary!['pendingTasks']}', Colors.grey),
                  _buildStatCard('Quá hạn', '${_summary!['overdueTasks']}', Colors.red),
                  _buildStatCard('Tỷ lệ hoàn thành', '${_summary!['completionRate']}%', Colors.teal),
                ],
              ),
            const SizedBox(height: 32),
            const Text(
              '2. Hiệu suất theo thành viên (E1.2)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _userPerformance.isEmpty
                ? const Text('Chưa có dữ liệu thành viên')
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userPerformance.length,
              itemBuilder: (context, index) {
                final item = _userPerformance[index];
                final rate = (item['completionRate'] ?? 0).toDouble();
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(item['userName'] ?? item['email'] ?? 'N/A'),
                    subtitle: Text('Đã làm: ${item['completed']}/${item['totalAssigned']} công việc'),
                    trailing: Text(
                      '${rate.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return SizedBox(
      width: 160,
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}