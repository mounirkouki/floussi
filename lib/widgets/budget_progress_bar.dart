import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  final double progress;
  final bool isOverBudget;

  const BudgetProgressBar({
    super.key,
    required this.progress,
    this.isOverBudget = false,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = isOverBudget
        ? Colors.red.shade400
        : progress > 0.8
            ? Colors.orange.shade400
            : Colors.green.shade400;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}
