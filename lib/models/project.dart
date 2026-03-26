import 'dart:convert';
import 'task.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final double totalBudget;
  final DateTime createdAt;
  final List<Task> tasks;

  Project({
    required this.id,
    required this.name,
    this.description = '',
    required this.totalBudget,
    required this.createdAt,
    List<Task>? tasks,
  }) : tasks = tasks ?? [];

  double get totalAgreed =>
      tasks.fold(0.0, (sum, task) => sum + task.agreedAmount);

  double get totalSpent =>
      tasks.fold(0.0, (sum, task) => sum + task.totalPaid);

  double get remainingBudget => totalBudget - totalSpent;

  double get budgetProgress =>
      totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

  Project copyWith({
    String? id,
    String? name,
    String? description,
    double? totalBudget,
    DateTime? createdAt,
    List<Task>? tasks,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalBudget: totalBudget ?? this.totalBudget,
      createdAt: createdAt ?? this.createdAt,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'totalBudget': totalBudget,
      'createdAt': createdAt.toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      totalBudget: (json['totalBudget'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  static String encodeList(List<Project> projects) =>
      jsonEncode(projects.map((p) => p.toJson()).toList());

  static List<Project> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
  }
}
