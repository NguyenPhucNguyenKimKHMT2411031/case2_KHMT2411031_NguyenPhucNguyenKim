class Task {
  final String id;
  final String title;
  final String description;
  final String status;
  final String userId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.userId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'status': status,
      'userId': userId,
    };
  }
}