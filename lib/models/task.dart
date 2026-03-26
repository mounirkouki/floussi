class Task {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final double agreedAmount;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.projectId,
    required this.name,
    this.description = '',
    required this.agreedAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'name': name,
      'description': description,
      'agreed_amount': agreedAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      agreedAmount: (map['agreed_amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Task copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    double? agreedAmount,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      agreedAmount: agreedAmount ?? this.agreedAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
