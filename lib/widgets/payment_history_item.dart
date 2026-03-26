import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../utils/formatters.dart';
import '../utils/app_theme.dart';

class PaymentHistoryItem extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onDelete;

  const PaymentHistoryItem({
    super.key,
    required this.payment,
    this.onDelete,
  });

  Color get _typeColor {
    switch (payment.type) {
      case PaymentType.advance:
        return AppTheme.accent;
      case PaymentType.payment:
        return AppTheme.primaryLight;
      case PaymentType.refund:
        return AppTheme.success;
    }
  }

  IconData get _typeIcon {
    switch (payment.type) {
      case PaymentType.advance:
        return Icons.arrow_upward_rounded;
      case PaymentType.payment:
        return Icons.check_circle_outline_rounded;
      case PaymentType.refund:
        return Icons.arrow_downward_rounded;
    }
  }

  String get _typeLabel {
    switch (payment.type) {
      case PaymentType.advance:
        return 'Avance';
      case PaymentType.payment:
        return 'Paiement';
      case PaymentType.refund:
        return 'Remboursement';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _typeColor.withAlpha(40),
          child: Icon(_typeIcon, color: _typeColor, size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _typeLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              payment.type == PaymentType.refund
                  ? '-${AppFormatters.currency(payment.amount)}'
                  : AppFormatters.currency(payment.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: payment.type == PaymentType.refund
                    ? AppTheme.success
                    : AppTheme.danger,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (payment.note.isNotEmpty)
              Text(payment.note,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(
              AppFormatters.date(payment.date),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }
}
