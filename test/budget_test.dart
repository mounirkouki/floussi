import 'package:flutter_test/flutter_test.dart';
import 'package:floussi/models/project.dart';
import 'package:floussi/models/task.dart';
import 'package:floussi/models/payment.dart';
import 'package:floussi/providers/budget_provider.dart';
import 'package:floussi/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// In-memory DatabaseHelper for tests.
class InMemoryDatabaseHelper extends DatabaseHelper {
  InMemoryDatabaseHelper() : super.testOnly();

  Database? _db;

  @override
  Future<Database> get database async {
    if (_db != null) return _db!;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE projects (
            id TEXT PRIMARY KEY, name TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            total_budget REAL NOT NULL, created_at TEXT NOT NULL)
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY, project_id TEXT NOT NULL,
            name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '',
            agreed_amount REAL NOT NULL, created_at TEXT NOT NULL,
            FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE)
        ''');
        await db.execute('''
          CREATE TABLE payments (
            id TEXT PRIMARY KEY, task_id TEXT NOT NULL,
            project_id TEXT NOT NULL, amount REAL NOT NULL,
            type TEXT NOT NULL, note TEXT NOT NULL DEFAULT '',
            date TEXT NOT NULL,
            FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
            FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE)
        ''');
      },
    );
    return _db!;
  }
}

void main() {
  // ─── Model serialisation ─────────────────────────────────────────────────

  group('Project model', () {
    test('toMap / fromMap round-trip', () {
      final now = DateTime(2024, 6, 1, 10, 0, 0);
      final project = Project(
        id: 'p1',
        name: 'Maison',
        description: 'Construction',
        totalBudget: 500000,
        createdAt: now,
      );
      final restored = Project.fromMap(project.toMap());

      expect(restored.id, project.id);
      expect(restored.name, project.name);
      expect(restored.description, project.description);
      expect(restored.totalBudget, project.totalBudget);
      expect(restored.createdAt, project.createdAt);
    });

    test('copyWith preserves unchanged fields', () {
      final p = Project(
        id: 'p1',
        name: 'Maison',
        totalBudget: 100000,
        createdAt: DateTime.now(),
      );
      final copy = p.copyWith(name: 'Villa');
      expect(copy.name, 'Villa');
      expect(copy.id, p.id);
      expect(copy.totalBudget, p.totalBudget);
    });
  });

  group('Task model', () {
    test('toMap / fromMap round-trip', () {
      final now = DateTime(2024, 7, 15);
      final task = Task(
        id: 't1',
        projectId: 'p1',
        name: 'Maçon',
        description: 'Gros œuvre',
        agreedAmount: 80000,
        createdAt: now,
      );
      final restored = Task.fromMap(task.toMap());
      expect(restored.id, task.id);
      expect(restored.projectId, task.projectId);
      expect(restored.agreedAmount, task.agreedAmount);
    });

    test('copyWith preserves unchanged fields', () {
      final t = Task(
        id: 't1',
        projectId: 'p1',
        name: 'Peintre',
        agreedAmount: 15000,
        createdAt: DateTime.now(),
      );
      final copy = t.copyWith(agreedAmount: 20000);
      expect(copy.agreedAmount, 20000);
      expect(copy.name, t.name);
    });
  });

  group('Payment model', () {
    test('toMap / fromMap round-trip for advance', () {
      final payment = Payment(
        id: 'pay1',
        taskId: 't1',
        projectId: 'p1',
        amount: 10000,
        type: PaymentType.advance,
        note: 'Première avance',
        date: DateTime(2024, 8, 1),
      );
      final restored = Payment.fromMap(payment.toMap());
      expect(restored.type, PaymentType.advance);
      expect(restored.amount, 10000);
      expect(restored.signedAmount, 10000);
    });

    test('signedAmount is negative for refund', () {
      final refund = Payment(
        id: 'ref1',
        taskId: 't1',
        projectId: 'p1',
        amount: 5000,
        type: PaymentType.refund,
        note: '',
        date: DateTime.now(),
      );
      expect(refund.signedAmount, -5000);
    });

    test('signedAmount is positive for payment', () {
      final pay = Payment(
        id: 'pay2',
        taskId: 't1',
        projectId: 'p1',
        amount: 20000,
        type: PaymentType.payment,
        note: '',
        date: DateTime.now(),
      );
      expect(pay.signedAmount, 20000);
    });

    test('all PaymentType values serialize / deserialize', () {
      for (final type in PaymentType.values) {
        final p = Payment(
          id: 'x',
          taskId: 't',
          projectId: 'p',
          amount: 100,
          type: type,
          note: '',
          date: DateTime.now(),
        );
        expect(Payment.fromMap(p.toMap()).type, type);
      }
    });
  });

  // ─── BudgetProvider calculations ─────────────────────────────────────────

  group('BudgetProvider budget calculations', () {
    late BudgetProvider provider;

    setUp(() {
      provider = BudgetProvider(db: InMemoryDatabaseHelper());
    });

    test('adding a project makes it visible in projects list', () async {
      await provider.addProject('Maison', 'Construction', 500000);
      expect(provider.projects, hasLength(1));
      expect(provider.projects.first.name, 'Maison');
      expect(provider.projects.first.totalBudget, 500000);
    });

    test('remainingBudgetForProject with no payments equals totalBudget',
        () async {
      await provider.addProject('Test', '', 100000);
      final p = provider.projects.first;
      expect(provider.totalSpentForProject(p.id), 0);
      expect(provider.remainingBudgetForProject(p), 100000);
    });

    test('totalPaidForTask accumulates advances correctly', () async {
      await provider.addProject('Projet', '', 200000);
      final p = provider.projects.first;
      await provider.addTask(p.id, 'Peintre', '', 30000);
      final tasks = await provider.getTasksForProject(p.id);
      final task = tasks.first;

      await provider.addPayment(
          task.id, p.id, 5000, PaymentType.advance, '', DateTime.now());
      await provider.addPayment(
          task.id, p.id, 3000, PaymentType.advance, '', DateTime.now());

      expect(provider.totalPaidForTask(task.id), 8000);
      expect(provider.remainingForTask(task), 22000);
    });

    test('refund reduces total paid', () async {
      await provider.addProject('Projet2', '', 100000);
      final p = provider.projects.first;
      await provider.addTask(p.id, 'Menuisier', '', 20000);
      final tasks = await provider.getTasksForProject(p.id);
      final task = tasks.first;

      await provider.addPayment(
          task.id, p.id, 10000, PaymentType.advance, '', DateTime.now());
      await provider.addPayment(
          task.id, p.id, 2000, PaymentType.refund, '', DateTime.now());

      expect(provider.totalPaidForTask(task.id), 8000);
      expect(provider.remainingForTask(task), 12000);
    });

    test('delete project removes it from list', () async {
      await provider.addProject('À supprimer', '', 50000);
      expect(provider.projects, hasLength(1));
      final id = provider.projects.first.id;
      await provider.deleteProject(id);
      expect(provider.projects.any((p) => p.id == id), isFalse);
    });

    test('updateProject reflects changes', () async {
      await provider.addProject('Ancien nom', '', 100000);
      final p = provider.projects.first;
      await provider.updateProject(p.copyWith(name: 'Nouveau nom'));
      expect(provider.projects.first.name, 'Nouveau nom');
    });

    test('totalAllocatedForProject sums task agreedAmounts', () async {
      await provider.addProject('Multi', '', 300000);
      final p = provider.projects.first;
      await provider.addTask(p.id, 'Maçon', '', 80000);
      await provider.addTask(p.id, 'Plombier', '', 40000);
      await provider.getTasksForProject(p.id);
      expect(provider.totalAllocatedForProject(p.id), 120000);
    });
  });
}
