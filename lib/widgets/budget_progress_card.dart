import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import '../utils/app_theme.dart';

class BudgetProgressCard extends StatelessWidget {
  final String label;
  final double spent;
  final double total;
  final Color? color;

  const BudgetProgressCard({
    super.key,
    required this.label,
    required this.spent,
    required this.total,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final remaining = total - spent;
    final isOver = remaining < 0;
    final effectiveColor = color ?? (isOver ? AppTheme.danger : AppTheme.primaryLight);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(
                label: 'Dépensé',
                value: AppFormatters.currency(spent),
                color: effectiveColor,
              ),
              _Stat(
                label: isOver ? 'Dépassement' : 'Restant',
                value: AppFormatters.currency(remaining.abs()),
                color: isOver ? AppTheme.danger : AppTheme.success,
              ),
              _Stat(
                label: 'Total',
                value: AppFormatters.currency(total),
                color: Colors.grey.shade700,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              AppFormatters.percentage(spent, total),
              style: TextStyle(
                fontSize: 12,
                color: effectiveColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12, color: color)),
      ],
    );
  }
}
