import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _myTaskStats;
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
    final myStatsRes = await ApiService.getMyTaskStats();
    final perfRes = await ApiService.getUserPerformance();

    if (mounted) {
      setState(() {
        if (summaryRes['success']) _summary = summaryRes['data'];
        if (myStatsRes['success']) _myTaskStats = myStatsRes['data'];
        if (perfRes['success']) _userPerformance = perfRes['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê công việc (Màn 10)'),
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
            const Text('1. Thống kê theo trạng thái (E1.1)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_summary != null)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatCard('Tổng công việc', '${_summary!['totalTasks']}', Colors.blue),
                  _buildStatCard('Đã hoàn thành', '${_summary!['completedTasks']}', Colors.green),
                  _buildStatCard('Đang thực hiện', '${_summary!['inProgressTasks']}', Colors.orange),
                  _buildStatCard('Chờ xử lý', '${_summary!['pendingTasks']}', Colors.grey),
                  _buildStatCard('Đã quá hạn', '${_summary!['overdueTasks']}', Colors.red),
                  _buildStatCard('Tỷ lệ xong', '${_summary!['completionRate']}%', Colors.teal),
                ],
              ),
            const SizedBox(height: 28),
            const Text('2. Công việc được giao & Phụ trách (E1.3)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_myTaskStats != null)
              Row(
                children: [
                  Expanded(
                    child: _buildInfoTile('Phụ trách chính', '${_myTaskStats!['primaryTasks']}', Icons.star, Colors.amber.shade800),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoTile('Được giao', '${_myTaskStats!['assignedTasks']}', Icons.assignment_ind, Colors.indigo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoTile('Do tôi tạo', '${_myTaskStats!['createdTasks']}', Icons.create_new_folder, Colors.purple),
                  ),
                ],
              ),
            const SizedBox(height: 28),
            const Text('3. Hiệu suất theo thành viên (E1.2)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    subtitle: Text('Hoàn thành: ${item['completed']}/${item['totalAssigned']} task'),
                    trailing: Text('${rate.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
      width: 150,
      child: Card(
        color: color.withOpacity(0.08),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
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

  Widget _buildInfoTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}