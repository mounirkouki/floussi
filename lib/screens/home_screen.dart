import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/project.dart';
import '../widgets/project_card.dart';
import '../widgets/summary_card.dart';
import 'project_detail_screen.dart';
import 'add_project_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'فلوسي',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF1A6B4A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildGlobalSummary(provider),
              ),
              if (provider.projects.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(context),
                )
              else ...[
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Mes Projets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final project = provider.projects[index];
                        return ProjectCard(
                          project: project,
                          onTap: () => _openProject(context, project),
                          onDelete: () => _confirmDelete(
                            context,
                            provider,
                            project,
                          ),
                        );
                      },
                      childCount: provider.projects.length,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addProject(context),
        backgroundColor: const Color(0xFF1A6B4A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Projet'),
      ),
    );
  }

  Widget _buildGlobalSummary(BudgetProvider provider) {
    return Container(
      color: const Color(0xFF1A6B4A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: 'Budget Total',
                  amount: provider.totalBudgetAllProjects,
                  icon: Icons.account_balance_wallet,
                  color: Colors.white,
                  textColor: const Color(0xFF1A6B4A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: 'Total Dépensé',
                  amount: provider.totalSpentAllProjects,
                  icon: Icons.payments,
                  color: Colors.white,
                  textColor: const Color(0xFFE53E3E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: 'Restant',
                  amount: provider.totalRemainingAllProjects,
                  icon: Icons.savings,
                  color: Colors.white,
                  textColor: provider.totalRemainingAllProjects >= 0
                      ? const Color(0xFF1A6B4A)
                      : const Color(0xFFE53E3E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun projet pour le moment',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier projet\nen appuyant sur le bouton +',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _addProject(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6B4A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Créer un projet'),
          ),
        ],
      ),
    );
  }

  void _openProject(BuildContext context, Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: project.id),
      ),
    );
  }

  void _addProject(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProjectScreen()),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BudgetProvider provider,
    Project project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le projet'),
        content: Text(
          'Voulez-vous vraiment supprimer "${project.name}" ?\nToutes les données seront perdues.',
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
      await provider.deleteProject(project.id);
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'فلوسي - Floussi',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024',
      children: const [
        SizedBox(height: 12),
        Text(
          'Application de gestion de budget pour vos projets et achats.',
        ),
      ],
    );
  }
}
