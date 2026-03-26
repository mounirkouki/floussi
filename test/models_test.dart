import 'package:flutter_test/flutter_test.dart';
import 'package:floussi/models/project.dart';
import 'package:floussi/models/task.dart';
import 'package:floussi/models/payment.dart';

void main() {
  group('Payment model', () {
    test('serializes and deserializes correctly', () {
      final payment = Payment(
        id: 'pay-1',
        taskId: 'task-1',
        amount: 50000.0,
        date: DateTime(2024, 1, 15),
        note: 'Avance initiale',
      );

      final json = payment.toJson();
      final restored = Payment.fromJson(json);

      expect(restored.id, equals(payment.id));
      expect(restored.taskId, equals(payment.taskId));
      expect(restored.amount, equals(payment.amount));
      expect(restored.date, equals(payment.date));
      expect(restored.note, equals(payment.note));
    });

    test('copyWith works correctly', () {
      final original = Payment(
        id: 'pay-1',
        taskId: 'task-1',
        amount: 50000.0,
        date: DateTime(2024, 1, 15),
        note: '',
      );
      final updated = original.copyWith(amount: 75000.0, note: 'Solde');

      expect(updated.id, equals(original.id));
      expect(updated.amount, equals(75000.0));
      expect(updated.note, equals('Solde'));
    });
  });

  group('Task model', () {
    test('calculates totalPaid correctly', () {
      final task = Task(
        id: 'task-1',
        projectId: 'proj-1',
        name: 'Constructeur',
        agreedAmount: 200000.0,
        createdAt: DateTime(2024, 1, 1),
        payments: [
          Payment(
            id: 'pay-1',
            taskId: 'task-1',
            amount: 50000.0,
            date: DateTime(2024, 1, 10),
          ),
          Payment(
            id: 'pay-2',
            taskId: 'task-1',
            amount: 80000.0,
            date: DateTime(2024, 2, 5),
          ),
        ],
      );

      expect(task.totalPaid, equals(130000.0));
      expect(task.remaining, equals(70000.0));
      expect(task.progress, closeTo(0.65, 0.001));
      expect(task.isOverBudget, isFalse);
    });

    test('detects over-budget correctly', () {
      final task = Task(
        id: 'task-2',
        projectId: 'proj-1',
        name: 'Menuisier',
        agreedAmount: 100000.0,
        createdAt: DateTime(2024, 1, 1),
        payments: [
          Payment(
            id: 'pay-3',
            taskId: 'task-2',
            amount: 120000.0,
            date: DateTime(2024, 3, 1),
          ),
        ],
      );

      expect(task.isOverBudget, isTrue);
      expect(task.remaining, equals(-20000.0));
    });

    test('serializes and deserializes correctly', () {
      final task = Task(
        id: 'task-1',
        projectId: 'proj-1',
        name: 'Plombier',
        agreedAmount: 150000.0,
        createdAt: DateTime(2024, 1, 1),
        payments: [
          Payment(
            id: 'pay-1',
            taskId: 'task-1',
            amount: 30000.0,
            date: DateTime(2024, 1, 20),
            note: 'Avance',
          ),
        ],
      );

      final json = task.toJson();
      final restored = Task.fromJson(json);

      expect(restored.id, equals(task.id));
      expect(restored.name, equals(task.name));
      expect(restored.agreedAmount, equals(task.agreedAmount));
      expect(restored.payments.length, equals(1));
      expect(restored.payments.first.amount, equals(30000.0));
    });
  });

  group('Project model', () {
    test('calculates totals correctly', () {
      final project = Project(
        id: 'proj-1',
        name: 'Construction Maison',
        totalBudget: 5000000.0,
        createdAt: DateTime(2024, 1, 1),
        tasks: [
          Task(
            id: 'task-1',
            projectId: 'proj-1',
            name: 'بناء - Constructeur',
            agreedAmount: 2000000.0,
            createdAt: DateTime(2024, 1, 5),
            payments: [
              Payment(
                id: 'pay-1',
                taskId: 'task-1',
                amount: 500000.0,
                date: DateTime(2024, 2, 1),
              ),
              Payment(
                id: 'pay-2',
                taskId: 'task-1',
                amount: 300000.0,
                date: DateTime(2024, 3, 1),
              ),
            ],
          ),
          Task(
            id: 'task-2',
            projectId: 'proj-1',
            name: 'نجار - Menuisier',
            agreedAmount: 800000.0,
            createdAt: DateTime(2024, 1, 6),
            payments: [
              Payment(
                id: 'pay-3',
                taskId: 'task-2',
                amount: 200000.0,
                date: DateTime(2024, 2, 15),
              ),
            ],
          ),
        ],
      );

      expect(project.totalSpent, equals(1000000.0));
      expect(project.remainingBudget, equals(4000000.0));
      expect(project.budgetProgress, closeTo(0.2, 0.001));
    });

    test('serializes and deserializes correctly', () {
      final project = Project(
        id: 'proj-1',
        name: 'Construction Maison',
        description: 'Projet de construction et finition',
        totalBudget: 5000000.0,
        createdAt: DateTime(2024, 1, 1),
        tasks: [
          Task(
            id: 'task-1',
            projectId: 'proj-1',
            name: 'Constructeur',
            agreedAmount: 2000000.0,
            createdAt: DateTime(2024, 1, 5),
          ),
        ],
      );

      final jsonStr = Project.encodeList([project]);
      final restored = Project.decodeList(jsonStr);

      expect(restored.length, equals(1));
      expect(restored.first.id, equals(project.id));
      expect(restored.first.name, equals(project.name));
      expect(restored.first.description, equals(project.description));
      expect(restored.first.totalBudget, equals(project.totalBudget));
      expect(restored.first.tasks.length, equals(1));
    });

    test('budgetProgress clamps to 1.0 when over budget', () {
      final project = Project(
        id: 'proj-2',
        name: 'Rénovation',
        totalBudget: 100000.0,
        createdAt: DateTime(2024, 1, 1),
        tasks: [
          Task(
            id: 'task-1',
            projectId: 'proj-2',
            name: 'Peintre',
            agreedAmount: 150000.0,
            createdAt: DateTime(2024, 1, 1),
            payments: [
              Payment(
                id: 'pay-1',
                taskId: 'task-1',
                amount: 150000.0,
                date: DateTime(2024, 1, 10),
              ),
            ],
          ),
        ],
      );

      expect(project.budgetProgress, equals(1.0));
    });
  });
}
