import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/payment.dart';

class BudgetProvider extends ChangeNotifier {
  static const String _storageKey = 'floussi_projects';

  final Uuid _uuid = const Uuid();
  List<Project> _projects = [];
  bool _isLoading = false;

  List<Project> get projects => List.unmodifiable(_projects);
  bool get isLoading => _isLoading;

  double get totalBudgetAllProjects =>
      _projects.fold(0.0, (sum, p) => sum + p.totalBudget);

  double get totalSpentAllProjects =>
      _projects.fold(0.0, (sum, p) => sum + p.totalSpent);

  double get totalRemainingAllProjects =>
      totalBudgetAllProjects - totalSpentAllProjects;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        _projects = Project.decodeList(jsonStr);
      }
    } catch (_) {
      _projects = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, Project.encodeList(_projects));
    } catch (_) {}
  }

  // --- Projects ---

  Future<void> addProject({
    required String name,
    required String description,
    required double totalBudget,
  }) async {
    final project = Project(
      id: _uuid.v4(),
      name: name,
      description: description,
      totalBudget: totalBudget,
      createdAt: DateTime.now(),
    );
    _projects = [project, ..._projects];
    notifyListeners();
    await _persist();
  }

  Future<void> updateProject({
    required String projectId,
    required String name,
    required String description,
    required double totalBudget,
  }) async {
    _projects = _projects.map((p) {
      if (p.id == projectId) {
        return p.copyWith(
          name: name,
          description: description,
          totalBudget: totalBudget,
        );
      }
      return p;
    }).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> deleteProject(String projectId) async {
    _projects = _projects.where((p) => p.id != projectId).toList();
    notifyListeners();
    await _persist();
  }

  Project? getProjectById(String projectId) {
    try {
      return _projects.firstWhere((p) => p.id == projectId);
    } catch (_) {
      return null;
    }
  }

  // --- Tasks ---

  Future<void> addTask({
    required String projectId,
    required String name,
    required double agreedAmount,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      projectId: projectId,
      name: name,
      agreedAmount: agreedAmount,
      createdAt: DateTime.now(),
    );
    _projects = _projects.map((p) {
      if (p.id == projectId) {
        return p.copyWith(tasks: [...p.tasks, task]);
      }
      return p;
    }).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> updateTask({
    required String projectId,
    required String taskId,
    required String name,
    required double agreedAmount,
  }) async {
    _projects = _projects.map((p) {
      if (p.id == projectId) {
        final updatedTasks = p.tasks.map((t) {
          if (t.id == taskId) {
            return t.copyWith(name: name, agreedAmount: agreedAmount);
          }
          return t;
        }).toList();
        return p.copyWith(tasks: updatedTasks);
      }
      return p;
    }).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> deleteTask({
    required String projectId,
    required String taskId,
  }) async {
    _projects = _projects.map((p) {
      if (p.id == projectId) {
        return p.copyWith(
          tasks: p.tasks.where((t) => t.id != taskId).toList(),
        );
      }
      return p;
    }).toList();
    notifyListeners();
    await _persist();
  }

  // --- Payments ---

  Future<void> addPayment({
    required String projectId,
    required String taskId,
    required double amount,
    required DateTime date,
    required String note,
  }) async {
    final payment = Payment(
      id: _uuid.v4(),
      taskId: taskId,
      amount: amount,
      date: date,
      note: note,
    );
    _projects = _projects.map((p) {
      if (p.id == projectId) {
        final updatedTasks = p.tasks.map((t) {
          if (t.id == taskId) {
            return t.copyWith(payments: [...t.payments, payment]);
          }
          return t;
        }).toList();
        return p.copyWith(tasks: updatedTasks);
      }
      return p;
    }).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> deletePayment({
    required String projectId,
    required String taskId,
    required String paymentId,
  }) async {
    _projects = _projects.map((p) {
      if (p.id == projectId) {
        final updatedTasks = p.tasks.map((t) {
          if (t.id == taskId) {
            return t.copyWith(
              payments: t.payments.where((pay) => pay.id != paymentId).toList(),
            );
          }
          return t;
        }).toList();
        return p.copyWith(tasks: updatedTasks);
      }
      return p;
    }).toList();
    notifyListeners();
    await _persist();
  }

  /// All payments across all projects, sorted by date descending.
  List<Map<String, dynamic>> getAllPaymentHistory() {
    final result = <Map<String, dynamic>>[];
    for (final project in _projects) {
      for (final task in project.tasks) {
        for (final payment in task.payments) {
          result.add({
            'payment': payment,
            'taskName': task.name,
            'projectName': project.name,
            'projectId': project.id,
            'taskId': task.id,
          });
        }
      }
    }
    result.sort((a, b) {
      final pa = a['payment'] as Payment;
      final pb = b['payment'] as Payment;
      return pb.date.compareTo(pa.date);
    });
    return result;
  }
}
