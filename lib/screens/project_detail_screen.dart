import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import '../widgets/budget_progress_bar.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';
import 'add_project_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final project = provider.getProjectById(projectId);

        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Projet introuvable')),
            body: const Center(child: Text('Ce projet n\'existe plus.')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: Text(
              project.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF1A6B4A),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editProject(context, project),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildProjectSummary(context, project),
              ),
              if (project.description.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      project.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Travaux / Prestataires',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ),
              if (project.tasks.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyTasks(context, project),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = project.tasks[index];
                        return TaskCard(
                          task: task,
                          onTap: () => _openTask(context, project, task),
                          onDelete: () =>
                              _confirmDeleteTask(context, provider, project, task),
                        );
                      },
                      childCount: project.tasks.length,
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addTask(context, project),
            backgroundColor: const Color(0xFF1A6B4A),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter Travaux'),
          ),
        );
      },
    );
  }

  Widget _buildProjectSummary(BuildContext context, Project project) {
    final isOverBudget = project.remainingBudget < 0;
    return Container(
      color: const Color(0xFF1A6B4A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          Row(
            children: [
              _buildSummaryItem(
                'Budget Total',
                project.totalBudget,
                Icons.account_balance_wallet,
                Colors.white,
              ),
              const SizedBox(width: 8),
              _buildSummaryItem(
                'Dépensé',
                project.totalSpent,
                Icons.payments,
                Colors.orange.shade100,
              ),
              const SizedBox(width: 8),
              _buildSummaryItem(
                'Restant',
                project.remainingBudget,
                Icons.savings,
                isOverBudget ? Colors.red.shade100 : Colors.green.shade100,
              ),
            ],
          ),
          const SizedBox(height: 16),
          BudgetProgressBar(
            progress: project.budgetProgress,
            isOverBudget: isOverBudget,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(project.budgetProgress * 100).toStringAsFixed(1)}% utilisé',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                '${project.tasks.length} travaux',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double amount,
    IconData icon,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bgColor.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: bgColor, size: 20),
            const SizedBox(height: 4),
            Text(
              _formatAmount(amount),
              style: TextStyle(
                color: bgColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: bgColor.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTasks(BuildContext context, Project project) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun travaux déclaré',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos travaux ou prestataires\n(Constructeur, Menuisier, Peintre…)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addTask(context, project),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6B4A),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter des travaux'),
          ),
        ],
      ),
    );
  }

  void _openTask(BuildContext context, Project project, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          projectId: project.id,
          taskId: task.id,
        ),
      ),
    );
  }

  void _addTask(BuildContext context, Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(projectId: project.id),
      ),
    );
  }

  void _editProject(BuildContext context, Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProjectScreen(project: project),
      ),
    );
  }

  Future<void> _confirmDeleteTask(
    BuildContext context,
    BudgetProvider provider,
    Project project,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer les travaux'),
        content: Text(
          'Voulez-vous vraiment supprimer "${task.name}" ?\nTout l\'historique de paiement sera perdu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteTask(projectId: project.id, taskId: task.id);
    }
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
