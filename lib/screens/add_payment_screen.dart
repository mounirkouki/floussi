import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/task.dart';
import '../models/payment.dart';
import '../utils/formatters.dart';
import '../utils/app_theme.dart';

class AddPaymentScreen extends StatefulWidget {
  final Task task;
  const AddPaymentScreen({super.key, required this.task});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  PaymentType _selectedType = PaymentType.advance;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
    await context.read<BudgetProvider>().addPayment(
          widget.task.id,
          widget.task.projectId,
          amount,
          _selectedType,
          _noteCtrl.text.trim(),
          _selectedDate,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = context
        .watch<BudgetProvider>()
        .remainingForTask(widget.task);

    return Scaffold(
      appBar: AppBar(
        title: Text('Paiement – ${widget.task.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Task Info Banner ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.primary.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.task.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Montant convenu: ${AppFormatters.currency(widget.task.agreedAmount)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Restant: ${AppFormatters.currency(remaining)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: remaining < 0
                                ? AppTheme.danger
                                : AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Payment Type ─────────────────────────────────────────
              const Text(
                'Type de paiement',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: PaymentType.values.map((type) {
                  final selected = _selectedType == type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _TypeButton(
                        type: type,
                        selected: selected,
                        onTap: () => setState(() => _selectedType = type),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ─── Amount ───────────────────────────────────────────────
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Montant (MAD) *',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'MAD',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ requis';
                  final val = double.tryParse(v.replaceAll(',', '.'));
                  if (val == null || val <= 0) return 'Montant invalide';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ─── Date ─────────────────────────────────────────────────
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date du paiement',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(AppFormatters.date(_selectedDate)),
                ),
              ),

              const SizedBox(height: 16),

              // ─── Note ─────────────────────────────────────────────────
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note / Remarque',
                  hintText: 'Optionnel',
                  prefixIcon: Icon(Icons.comment_outlined),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Enregistrer le paiement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final PaymentType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  String get label {
    switch (type) {
      case PaymentType.advance:
        return 'Avance';
      case PaymentType.payment:
        return 'Paiement';
      case PaymentType.refund:
        return 'Remboursement';
    }
  }

  IconData get icon {
    switch (type) {
      case PaymentType.advance:
        return Icons.arrow_upward_rounded;
      case PaymentType.payment:
        return Icons.check_circle_outline_rounded;
      case PaymentType.refund:
        return Icons.arrow_downward_rounded;
    }
  }

  Color get color {
    switch (type) {
      case PaymentType.advance:
        return AppTheme.accent;
      case PaymentType.payment:
        return AppTheme.primaryLight;
      case PaymentType.refund:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(40) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
