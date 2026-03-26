import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/task.dart';

class AddEditTaskScreen extends StatefulWidget {
  final String projectId;
  final Task? task;

  const AddEditTaskScreen({
    super.key,
    required this.projectId,
    this.task,
  });

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  bool _saving = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.task?.name ?? '');
    _descCtrl = TextEditingController(text: widget.task?.description ?? '');
    _amountCtrl = TextEditingController(
      text: widget.task != null
          ? widget.task!.agreedAmount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<BudgetProvider>();
    final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));

    if (_isEdit) {
      await provider.updateTask(
        widget.task!.copyWith(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          agreedAmount: amount,
        ),
      );
    } else {
      await provider.addTask(
        widget.projectId,
        _nameCtrl.text.trim(),
        _descCtrl.text.trim(),
        amount,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier la tâche' : 'Nouvelle tâche'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de la tâche *',
                  hintText: 'Ex : Maçon, Menuisier, Peintre...',
                  prefixIcon: Icon(Icons.handyman_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Description optionnelle',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Montant convenu (MAD) *',
                  hintText: 'Ex : 50000',
                  prefixIcon: Icon(Icons.handshake_outlined),
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
                label: Text(_isEdit ? 'Mettre à jour' : 'Créer la tâche'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
