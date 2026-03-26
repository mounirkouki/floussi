import 'payment.dart';

class Task {
  final String id;
  final String projectId;
  final String name;
  final double agreedAmount;
  final DateTime createdAt;
  final List<Payment> payments;

  Task({
    required this.id,
    required this.projectId,
    required this.name,
    required this.agreedAmount,
    required this.createdAt,
    List<Payment>? payments,
  }) : payments = payments ?? [];

  double get totalPaid =>
      payments.fold(0.0, (sum, p) => sum + p.amount);

  double get remaining => agreedAmount - totalPaid;

  double get progress =>
      agreedAmount > 0 ? (totalPaid / agreedAmount).clamp(0.0, 1.0) : 0.0;

  bool get isOverBudget => totalPaid > agreedAmount;

  Task copyWith({
    String? id,
    String? projectId,
    String? name,
    double? agreedAmount,
    DateTime? createdAt,
    List<Payment>? payments,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      agreedAmount: agreedAmount ?? this.agreedAmount,
      createdAt: createdAt ?? this.createdAt,
      payments: payments ?? this.payments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'agreedAmount': agreedAmount,
      'createdAt': createdAt.toIso8601String(),
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      agreedAmount: (json['agreedAmount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
