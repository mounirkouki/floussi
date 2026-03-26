import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/project.dart';

class AddProjectScreen extends StatefulWidget {
  final Project? project;

  const AddProjectScreen({super.key, this.project});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _budgetController;
  bool _isSaving = false;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.project?.description ?? '');
    _budgetController = TextEditingController(
      text: widget.project != null
          ? widget.project!.totalBudget.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier le projet' : 'Nouveau Projet',
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
            _buildCard(
              children: [
                _buildSectionTitle('Informations du projet'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    'Nom du projet',
                    'Ex: Construction maison, Rénovation…',
                    Icons.folder,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    if (v.trim().length < 2) {
                      return 'Nom trop court (minimum 2 caractères)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration(
                    'Description (optionnel)',
                    'Décrivez votre projet…',
                    Icons.description,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              children: [
                _buildSectionTitle('Budget'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _budgetController,
                  decoration: _inputDecoration(
                    'Budget total (DA)',
                    'Ex: 5000000',
                    Icons.account_balance_wallet,
                  ).copyWith(
                    suffixText: 'DA',
                  ),
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
                      return 'Le budget est requis';
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
                  'Définissez l\'enveloppe budgétaire totale de votre projet.',
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
                        _isEditing ? 'Enregistrer' : 'Créer le projet',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3748),
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
    final description = _descriptionController.text.trim();
    final budget = double.parse(_budgetController.text.trim());

    try {
      if (_isEditing) {
        await provider.updateProject(
          projectId: widget.project!.id,
          name: name,
          description: description,
          totalBudget: budget,
        );
      } else {
        await provider.addProject(
          name: name,
          description: description,
          totalBudget: budget,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Projet modifié avec succès'
                  : 'Projet créé avec succès',
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
