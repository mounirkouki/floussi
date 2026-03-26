import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../utils/formatters.dart';
import '../utils/app_theme.dart';
import '../widgets/budget_progress_card.dart';
import 'task_detail_screen.dart';
import 'add_edit_task_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<BudgetProvider>().refreshProject(widget.project.id);
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        // Get up-to-date project object
        final project = provider.projects
            .firstWhere((p) => p.id == widget.project.id,
                orElse: () => widget.project);

        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
            ],
          ),
          body: _loaded
              ? _buildBody(context, provider, project)
              : const Center(child: CircularProgressIndicator()),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddTask(context, project),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une tâche'),
          ),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context, BudgetProvider provider, Project project) {
    final tasks = provider.cachedTasksForProject(project.id);
    final totalSpent = provider.totalSpentForProject(project.id);
    final totalAllocated = provider.totalAllocatedForProject(project.id);

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // ─── Global Budget Summary ───────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: BudgetProgressCard(
            label: '📊 Budget global du projet',
            spent: totalSpent,
            total: project.totalBudget,
          ),
        ),

        // ─── Budget Allocation ───────────────────────────────────
        if (totalAllocated > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: BudgetProgressCard(
              label: '📋 Budget alloué aux tâches',
              spent: totalAllocated,
              total: project.totalBudget,
              color: AppTheme.secondary,
            ),
          ),

        // ─── Summary Stats ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _SummaryRow(
            items: [
              _SummaryItem(
                label: 'Tâches',
                value: tasks.length.toString(),
                icon: Icons.task_alt,
                color: AppTheme.primary,
              ),
              _SummaryItem(
                label: 'Alloué',
                value: AppFormatters.currency(totalAllocated),
                icon: Icons.assignment_outlined,
                color: AppTheme.secondary,
              ),
              _SummaryItem(
                label: 'Dépensé',
                value: AppFormatters.currency(totalSpent),
                icon: Icons.payments_outlined,
                color: AppTheme.danger,
              ),
              _SummaryItem(
                label: 'Restant',
                value: AppFormatters.currency(project.totalBudget - totalSpent),
                icon: Icons.savings_outlined,
                color: AppTheme.success,
              ),
            ],
          ),
        ),

        // ─── Tasks List ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Tâches (${tasks.length})',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),

        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.task_outlined,
                      size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune tâche définie.\nAjoutez vos premiers travaux !',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ...tasks.map((task) => _TaskCard(
                task: task,
                provider: provider,
                onTap: () => _openTaskDetail(context, task),
                onEdit: () => _openEditTask(context, project, task),
                onDelete: () =>
                    _confirmDeleteTask(context, provider, project, task),
              )),
      ],
    );
  }

  void _openAddTask(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => AddEditTaskScreen(projectId: project.id)),
    );
  }

  void _openEditTask(BuildContext context, Project project, Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) =>
              AddEditTaskScreen(projectId: project.id, task: task)),
    );
  }

  void _openTaskDetail(BuildContext context, Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
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
        title: const Text('Supprimer la tâche'),
        content: Text(
            'Voulez-vous supprimer "${task.name}" et tous ses paiements ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await provider.deleteTask(project.id, task.id);
    }
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final BudgetProvider provider;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.provider,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final paid = provider.totalPaidForTask(task.id);
    final remaining = provider.remainingForTask(task);
    final progress =
        task.agreedAmount > 0 ? (paid / task.agreedAmount).clamp(0.0, 1.0) : 0.0;
    final isOver = remaining < 0;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AppTheme.primaryLight.withAlpha(40),
                    radius: 18,
                    child: const Icon(Icons.handyman_outlined,
                        color: AppTheme.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        if (task.description.isNotEmpty)
                          Text(task.description,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Modifier'))),
                      const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                              leading: Icon(Icons.delete_outline,
                                  color: AppTheme.danger),
                              title: Text('Supprimer',
                                  style:
                                      TextStyle(color: AppTheme.danger)))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                    isOver ? AppTheme.danger : AppTheme.primaryLight),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Mini(
                    label: 'Convenu',
                    value: AppFormatters.currency(task.agreedAmount),
                    color: AppTheme.primary,
                  ),
                  _Mini(
                    label: 'Payé',
                    value: AppFormatters.currency(paid),
                    color: AppTheme.accent,
                  ),
                  _Mini(
                    label: isOver ? 'Dépassement' : 'Restant',
                    value: AppFormatters.currency(remaining.abs()),
                    color: isOver ? AppTheme.danger : AppTheme.success,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Mini(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<_SummaryItem> items;
  const _SummaryRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map((item) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: item.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(item.icon, color: item.color, size: 20),
                      const SizedBox(height: 4),
                      Text(item.value,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.color),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Text(item.label,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _SummaryItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
}
