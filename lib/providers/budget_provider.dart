import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/payment.dart';
import '../database/database_helper.dart';

class BudgetProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  final Uuid _uuid = const Uuid();

  List<Project> _projects = [];
  Map<String, List<Task>> _tasksByProject = {};
  Map<String, List<Payment>> _paymentsByTask = {};
  Map<String, List<Payment>> _paymentsByProject = {};

  bool _loading = false;

  BudgetProvider({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  List<Project> get projects => List.unmodifiable(_projects);
  bool get loading => _loading;

  // ─── Projects ─────────────────────────────────────────────────────────────

  Future<void> loadProjects() async {
    _loading = true;
    notifyListeners();
    _projects = await _db.getProjects();
    _loading = false;
    notifyListeners();
  }

  Future<void> addProject(String name, String description, double totalBudget) async {
    final project = Project(
      id: _uuid.v4(),
      name: name,
      description: description,
      totalBudget: totalBudget,
      createdAt: DateTime.now(),
    );
    await _db.insertProject(project);
    _projects.insert(0, project);
    notifyListeners();
  }

  Future<void> updateProject(Project updated) async {
    await _db.updateProject(updated);
    final idx = _projects.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _projects[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteProject(String projectId) async {
    await _db.deleteProject(projectId);
    _projects.removeWhere((p) => p.id == projectId);
    _tasksByProject.remove(projectId);
    _paymentsByProject.remove(projectId);
    notifyListeners();
  }

  // ─── Tasks ────────────────────────────────────────────────────────────────

  Future<List<Task>> getTasksForProject(String projectId) async {
    if (!_tasksByProject.containsKey(projectId)) {
      _tasksByProject[projectId] = await _db.getTasksForProject(projectId);
    }
    return List.unmodifiable(_tasksByProject[projectId]!);
  }

  Future<void> addTask(
    String projectId,
    String name,
    String description,
    double agreedAmount,
  ) async {
    final task = Task(
      id: _uuid.v4(),
      projectId: projectId,
      name: name,
      description: description,
      agreedAmount: agreedAmount,
      createdAt: DateTime.now(),
    );
    await _db.insertTask(task);
    _tasksByProject[projectId] ??= [];
    _tasksByProject[projectId]!.add(task);
    notifyListeners();
  }

  Future<void> updateTask(Task updated) async {
    await _db.updateTask(updated);
    final tasks = _tasksByProject[updated.projectId];
    if (tasks != null) {
      final idx = tasks.indexWhere((t) => t.id == updated.id);
      if (idx != -1) {
        tasks[idx] = updated;
        notifyListeners();
      }
    }
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    await _db.deleteTask(taskId);
    _tasksByProject[projectId]?.removeWhere((t) => t.id == taskId);
    _paymentsByTask.remove(taskId);
    // Invalidate project payments cache so totals are recalculated
    _paymentsByProject.remove(projectId);
    notifyListeners();
  }

  // ─── Payments ─────────────────────────────────────────────────────────────

  Future<List<Payment>> getPaymentsForTask(String taskId) async {
    if (!_paymentsByTask.containsKey(taskId)) {
      _paymentsByTask[taskId] = await _db.getPaymentsForTask(taskId);
    }
    return List.unmodifiable(_paymentsByTask[taskId]!);
  }

  Future<List<Payment>> getPaymentsForProject(String projectId) async {
    if (!_paymentsByProject.containsKey(projectId)) {
      _paymentsByProject[projectId] =
          await _db.getPaymentsForProject(projectId);
    }
    return List.unmodifiable(_paymentsByProject[projectId]!);
  }

  Future<void> addPayment(
    String taskId,
    String projectId,
    double amount,
    PaymentType type,
    String note,
    DateTime date,
  ) async {
    final payment = Payment(
      id: _uuid.v4(),
      taskId: taskId,
      projectId: projectId,
      amount: amount,
      type: type,
      note: note,
      date: date,
    );
    await _db.insertPayment(payment);
    _paymentsByTask[taskId] ??= [];
    _paymentsByTask[taskId]!.insert(0, payment);
    // Invalidate project payments cache
    _paymentsByProject.remove(projectId);
    notifyListeners();
  }

  Future<void> deletePayment(
    String paymentId,
    String taskId,
    String projectId,
  ) async {
    await _db.deletePayment(paymentId);
    _paymentsByTask[taskId]?.removeWhere((p) => p.id == paymentId);
    _paymentsByProject.remove(projectId);
    notifyListeners();
  }

  /// Returns cached tasks for a project (synchronous, after refreshProject is called).
  List<Task> cachedTasksForProject(String projectId) {
    return List.unmodifiable(_tasksByProject[projectId] ?? []);
  }

  /// Returns cached payments for a task (synchronous, after data is loaded).
  List<Payment> cachedPaymentsForTask(String taskId) {
    return List.unmodifiable(_paymentsByTask[taskId] ?? []);
  }


  /// Total amount paid for a task (advances + payments - refunds).
  double totalPaidForTask(String taskId) {
    final payments = _paymentsByTask[taskId] ?? [];
    return payments.fold(0.0, (sum, p) => sum + p.signedAmount);
  }

  /// Remaining amount for a task = agreedAmount - totalPaid.
  double remainingForTask(Task task) {
    return task.agreedAmount - totalPaidForTask(task.id);
  }

  /// Total allocated budget across all tasks in a project.
  double totalAllocatedForProject(String projectId) {
    final tasks = _tasksByProject[projectId] ?? [];
    return tasks.fold(0.0, (sum, t) => sum + t.agreedAmount);
  }

  /// Total spent (all payments) for a project.
  double totalSpentForProject(String projectId) {
    final payments = _paymentsByProject[projectId] ?? [];
    return payments.fold(0.0, (sum, p) => sum + p.signedAmount);
  }

  /// Remaining global budget for a project = totalBudget - totalSpent.
  double remainingBudgetForProject(Project project) {
    return project.totalBudget - totalSpentForProject(project.id);
  }

  /// Refresh all cached data for a project (tasks + payments).
  Future<void> refreshProject(String projectId) async {
    _tasksByProject[projectId] = await _db.getTasksForProject(projectId);
    _paymentsByProject[projectId] = await _db.getPaymentsForProject(projectId);
    // Refresh task payments for all tasks
    for (final task in _tasksByProject[projectId]!) {
      _paymentsByTask[task.id] = await _db.getPaymentsForTask(task.id);
    }
    notifyListeners();
  }
}
