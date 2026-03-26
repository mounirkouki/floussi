enum PaymentType { advance, payment, refund }

class Payment {
  final String id;
  final String taskId;
  final String projectId;
  final double amount;
  final PaymentType type;
  final String note;
  final DateTime date;

  Payment({
    required this.id,
    required this.taskId,
    required this.projectId,
    required this.amount,
    required this.type,
    this.note = '',
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'project_id': projectId,
      'amount': amount,
      'type': type.name,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      projectId: map['project_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: PaymentType.values.byName(map['type'] as String),
      note: (map['note'] as String?) ?? '',
      date: DateTime.parse(map['date'] as String),
    );
  }

  Payment copyWith({
    String? id,
    String? taskId,
    String? projectId,
    double? amount,
    PaymentType? type,
    String? note,
    DateTime? date,
  }) {
    return Payment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }

  /// Returns the effective signed amount based on payment type.
  /// Advances and payments reduce available budget (positive spend).
  /// Refunds restore available budget (negative spend).
  double get signedAmount {
    switch (type) {
      case PaymentType.advance:
      case PaymentType.payment:
        return amount;
      case PaymentType.refund:
        return -amount;
    }
  }
}
