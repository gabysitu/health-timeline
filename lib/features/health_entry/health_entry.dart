class HealthEntry {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String description;
  final DateTime createdAt;

  const HealthEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HealthEntry.fromMap(Map<String, dynamic> map) {
    return HealthEntry(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}