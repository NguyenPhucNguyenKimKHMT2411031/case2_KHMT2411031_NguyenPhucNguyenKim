class Task {
  final String id;
  final String title;
  final String description;
  final String status;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}