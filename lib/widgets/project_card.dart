import 'package:flutter/material.dart';
import '../models/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOverBudget = project.remainingBudget < 0;
    final progressColor = isOverBudget
        ? Colors.red.shade400
        : project.budgetProgress > 0.8
            ? Colors.orange.shade400
            : const Color(0xFF1A6B4A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: progressColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.folder,
                          color: progressColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            if (project.description.isNotEmpty)
                              Text(
                                project.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey[400],
                        ),
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
                                Text(
                                  'Supprimer',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildAmountBadge(
                        'Budget',
                        project.totalBudget,
                        Colors.grey[700]!,
                      ),
                      const SizedBox(width: 8),
                      _buildAmountBadge(
                        'Dépensé',
                        project.totalSpent,
                        Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      _buildAmountBadge(
                        isOverBudget ? 'Dépassé' : 'Restant',
                        isOverBudget
                            ? -project.remainingBudget
                            : project.remainingBudget,
                        isOverBudget
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: project.budgetProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(project.budgetProgress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: progressColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${project.tasks.length} travaux',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountBadge(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatAmount(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M DA';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K DA';
    }
    return '${amount.toStringAsFixed(0)} DA';
  }
}
