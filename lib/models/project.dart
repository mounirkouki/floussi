class Project {
  final String id;
  final String name;
  final String description;
  final double totalBudget;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    this.description = '',
    required this.totalBudget,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'total_budget': totalBudget,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      totalBudget: (map['total_budget'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    double? totalBudget,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalBudget: totalBudget ?? this.totalBudget,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
