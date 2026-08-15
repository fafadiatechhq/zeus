import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';
import 'api_providers.dart';
import 'dashboard_provider.dart';

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(ExpensesNotifier.new);

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() => _load();

  Future<List<Expense>> _load() async {
    final repo = ExpenseRepository(await requireApiClient());
    return repo.getMyExpenses();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(_load);
  }

  Future<Expense> createExpense({
    required String title,
    required double amount,
    required DateTime expenseDate,
    required ExpenseCategory category,
    String? notes,
    bool submit = false,
  }) async {
    final repo = ExpenseRepository(await requireApiClient());
    final created = await repo.createExpense(
      title: title,
      amount: amount,
      expenseDate: expenseDate,
      category: category,
      notes: notes,
      submit: submit,
    );
    ref.invalidate(dashboardProvider);
    state = await AsyncValue.guard(build);
    return created;
  }
}
