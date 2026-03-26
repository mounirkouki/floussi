import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  final String projectId;
  final Task? task;

  const AddTaskScreen({
    super.key,
    required this.projectId,
    this.task,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  // Predefined job types for quick selection
  static const _quickJobs = [
    ('بناء', 'Constructeur', Icons.construction),
    ('نجار', 'Menuisier', Icons.carpenter),
    ('الدهن', 'Peintre', Icons.format_paint),
    ('سباك', 'Plombier', Icons.plumbing),
    ('كهربائي', 'Électricien', Icons.electrical_services),
    ('معلم بلاط', 'Carreleur', Icons.grid_4x4),
    ('فران', 'Forgeron', Icons.hardware),
    ('زجاج', 'Vitrier', Icons.window),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task?.name ?? '');
    _amountController = TextEditingController(
      text: widget.task != null
          ? widget.task!.agreedAmount.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier les travaux' : 'Ajouter des travaux',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A6B4A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEditing) ...[
              _buildCard(
                children: [
                  const Text(
                    'Sélection rapide',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickJobs.map((job) {
                      return InkWell(
                        onTap: () {
                          _nameController.text = '${job.$1} - ${job.$2}';
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A6B4A).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF1A6B4A).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                job.$3,
                                size: 16,
                                color: const Color(0xFF1A6B4A),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                job.$2,
                                style: const TextStyle(
                                  color: Color(0xFF1A6B4A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _buildCard(
              children: [
                const Text(
                  'Détails des travaux',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    'Nom des travaux / Prestataire',
                    'Ex: Constructeur, Menuisier…',
                    Icons.person,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    if (v.trim().length < 2) {
                      return 'Nom trop court';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: _inputDecoration(
                    'Montant convenu (DA)',
                    'Ex: 150000',
                    Icons.handshake,
                  ).copyWith(suffixText: 'DA'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Le montant est requis';
                    }
                    final amount = double.tryParse(v.trim());
                    if (amount == null || amount <= 0) {
                      return 'Veuillez entrer un montant valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Montant total convenu avec le prestataire.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6B4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Enregistrer' : 'Ajouter les travaux',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1A6B4A)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A6B4A), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<BudgetProvider>();
    final name = _nameController.text.trim();
    final amount = double.parse(_amountController.text.trim());

    try {
      if (_isEditing) {
        await provider.updateTask(
          projectId: widget.projectId,
          taskId: widget.task!.id,
          name: name,
          agreedAmount: amount,
        );
      } else {
        await provider.addTask(
          projectId: widget.projectId,
          name: name,
          agreedAmount: amount,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Travaux modifiés avec succès'
                  : 'Travaux ajoutés avec succès',
            ),
            backgroundColor: const Color(0xFF1A6B4A),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
