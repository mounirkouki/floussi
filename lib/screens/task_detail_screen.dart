import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/task.dart';
import '../models/payment.dart';
import '../utils/formatters.dart';
import '../utils/app_theme.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/payment_history_item.dart';
import 'add_payment_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<BudgetProvider>().getPaymentsForTask(widget.task.id);
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.task.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
            ],
          ),
          body: _loaded
              ? _buildBody(context, provider)
              : const Center(child: CircularProgressIndicator()),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddPayment(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un paiement'),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BudgetProvider provider) {
    final payments = provider.cachedPaymentsForTask(widget.task.id);
    final paid = provider.totalPaidForTask(widget.task.id);
    final remaining = provider.remainingForTask(widget.task);

    // Separate advances from full payments
    final advances =
        payments.where((p) => p.type == PaymentType.advance).toList();
    final fullPayments =
        payments.where((p) => p.type == PaymentType.payment).toList();
    final refunds =
        payments.where((p) => p.type == PaymentType.refund).toList();

    final totalAdvances = advances.fold(0.0, (sum, p) => sum + p.amount);

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // ─── Task Budget Card ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: BudgetProgressCard(
            label: '💼 Budget de la tâche',
            spent: paid,
            total: widget.task.agreedAmount,
          ),
        ),

        // ─── Stats Row ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _StatChip(
                label: 'Convenu',
                value: AppFormatters.currency(widget.task.agreedAmount),
                color: AppTheme.primary,
                icon: Icons.handshake_outlined,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Avances',
                value: AppFormatters.currency(totalAdvances),
                color: AppTheme.accent,
                icon: Icons.arrow_upward_rounded,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: remaining < 0 ? 'Dépassement' : 'Restant',
                value: AppFormatters.currency(remaining.abs()),
                color: remaining < 0 ? AppTheme.danger : AppTheme.success,
                icon: remaining < 0
                    ? Icons.warning_amber_outlined
                    : Icons.savings_outlined,
              ),
            ],
          ),
        ),

        // ─── Task Info ────────────────────────────────────────────
        if (widget.task.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.task.description,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ─── Payment Summary Stats ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: _PaymentSummaryRow(
            advances: advances.length,
            payments: fullPayments.length,
            refunds: refunds.length,
          ),
        ),

        // ─── History Section ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Historique des paiements (${payments.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),

        if (payments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun paiement enregistré.\nAjoutez une avance ou un paiement !',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ...payments.map((payment) => PaymentHistoryItem(
                payment: payment,
                onDelete: () =>
                    _confirmDeletePayment(context, provider, payment),
              )),
      ],
    );
  }

  void _openAddPayment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPaymentScreen(
          task: widget.task,
        ),
      ),
    );
  }

  Future<void> _confirmDeletePayment(
    BuildContext context,
    BudgetProvider provider,
    Payment payment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le paiement'),
        content: Text(
            'Supprimer ce paiement de ${AppFormatters.currency(payment.amount)} ?'),
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
      await provider.deletePayment(
          payment.id, widget.task.id, widget.task.projectId);
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: color),
                textAlign: TextAlign.center,
                maxLines: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PaymentSummaryRow extends StatelessWidget {
  final int advances;
  final int payments;
  final int refunds;

  const _PaymentSummaryRow({
    required this.advances,
    required this.payments,
    required this.refunds,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Badge(
          label: 'Avances',
          count: advances,
          color: AppTheme.accent,
        ),
        const SizedBox(width: 8),
        _Badge(
          label: 'Paiements',
          count: payments,
          color: AppTheme.primaryLight,
        ),
        const SizedBox(width: 8),
        _Badge(
          label: 'Remboursements',
          count: refunds,
          color: AppTheme.success,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _Badge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 16),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
