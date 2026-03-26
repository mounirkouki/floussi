import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/task.dart';
import '../models/payment.dart';
import '../widgets/budget_progress_bar.dart';
import 'add_payment_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final String projectId;
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final project = provider.getProjectById(projectId);
        Task? task;
        if (project != null) {
          try {
            task = project.tasks.firstWhere((t) => t.id == taskId);
          } catch (_) {
            task = null;
          }
        }

        if (project == null || task == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Travail introuvable')),
            body: const Center(child: Text('Ce travail n\'existe plus.')),
          );
        }

        final payments = List<Payment>.from(task.payments)
          ..sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: Text(
              task.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF1A6B4A),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildTaskSummary(task),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Historique des paiements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ),
              if (payments.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyPayments(context),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final payment = payments[index];
                        return _buildPaymentItem(
                          context,
                          provider,
                          payment,
                          index,
                          payments.length,
                        );
                      },
                      childCount: payments.length,
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addPayment(context, task.name),
            backgroundColor: const Color(0xFF1A6B4A),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter Paiement'),
          ),
        );
      },
    );
  }

  Widget _buildTaskSummary(Task task) {
    final isOverBudget = task.remaining < 0;
    return Container(
      color: const Color(0xFF1A6B4A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatBox(
                'Montant Convenu',
                task.agreedAmount,
                Colors.white,
                Icons.handshake,
              ),
              const SizedBox(width: 8),
              _buildStatBox(
                'Total Payé',
                task.totalPaid,
                Colors.orange.shade100,
                Icons.payments,
              ),
              const SizedBox(width: 8),
              _buildStatBox(
                isOverBudget ? 'Dépassement' : 'Restant',
                isOverBudget ? -task.remaining : task.remaining,
                isOverBudget ? Colors.red.shade100 : Colors.green.shade100,
                isOverBudget ? Icons.warning : Icons.savings,
              ),
            ],
          ),
          const SizedBox(height: 16),
          BudgetProgressBar(
            progress: task.progress,
            isOverBudget: isOverBudget,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(task.progress * 100).toStringAsFixed(1)}% payé',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${task.payments.length} paiement(s)',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    double amount,
    Color bgColor,
    IconData icon,
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
            Icon(icon, color: bgColor, size: 18),
            const SizedBox(height: 4),
            Text(
              _formatAmount(amount),
              style: TextStyle(
                color: bgColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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

  Widget _buildPaymentItem(
    BuildContext context,
    BudgetProvider provider,
    Payment payment,
    int index,
    int total,
  ) {
    final dateStr = DateFormat('dd/MM/yyyy').format(payment.date);
    return Dismissible(
      key: Key(payment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer le paiement'),
            content: const Text(
              'Voulez-vous vraiment supprimer ce paiement ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        provider.deletePayment(
          projectId: projectId,
          taskId: taskId,
          paymentId: payment.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A6B4A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments,
              color: Color(0xFF1A6B4A),
            ),
          ),
          title: Text(
            '${payment.amount.toStringAsFixed(0)} DA',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2D3748),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              if (payment.note.isNotEmpty)
                Text(
                  payment.note,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A6B4A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${total - index}',
              style: const TextStyle(
                color: Color(0xFF1A6B4A),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPayments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun paiement enregistré',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez les avances et paiements\neffectués pour ce travail',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addPayment(context, ''),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6B4A),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un paiement'),
          ),
        ],
      ),
    );
  }

  void _addPayment(BuildContext context, String taskName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPaymentScreen(
          projectId: projectId,
          taskId: taskId,
          taskName: taskName,
        ),
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
