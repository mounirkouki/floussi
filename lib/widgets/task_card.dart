import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOverBudget = task.isOverBudget;
    final progressColor = isOverBudget
        ? Colors.red.shade400
        : task.progress > 0.8
            ? Colors.orange.shade400
            : const Color(0xFF1A6B4A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getTaskIcon(task.name),
                    color: progressColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        '${task.payments.length} paiement(s) · '
                        '${task.agreedAmount.toStringAsFixed(0)} DA convenu',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOverBudget ? '+ ${(-task.remaining).toStringAsFixed(0)}' : '${task.remaining.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isOverBudget
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                    Text(
                      isOverBudget ? 'dépassé' : 'restant',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 18),
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(task.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (isOverBudget) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.warning, size: 13, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Dépassement du budget convenu',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getTaskIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('بناء') || lower.contains('construct')) {
      return Icons.construction;
    } else if (lower.contains('نجار') || lower.contains('menuisier') || lower.contains('bois')) {
      return Icons.carpenter;
    } else if (lower.contains('دهن') || lower.contains('peintre') || lower.contains('pein')) {
      return Icons.format_paint;
    } else if (lower.contains('سباك') || lower.contains('plomb')) {
      return Icons.plumbing;
    } else if (lower.contains('كهرب') || lower.contains('électr')) {
      return Icons.electrical_services;
    } else if (lower.contains('بلاط') || lower.contains('carrela')) {
      return Icons.grid_4x4;
    } else {
      return Icons.build;
    }
  }
}
