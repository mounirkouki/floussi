class Payment {
  final String id;
  final String taskId;
  final double amount;
  final DateTime date;
  final String note;

  Payment({
    required this.id,
    required this.taskId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Payment copyWith({
    String? id,
    String? taskId,
    double? amount,
    DateTime? date,
    String? note,
  }) {
    return Payment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: (json['note'] as String?) ?? '',
    );
  }
}
