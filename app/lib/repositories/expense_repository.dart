import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/json_util.dart';
import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository(this._client);

  final ApiClient _client;

  Future<List<Expense>> getMyExpenses() async {
    final data = await _client.postMethod('zeus.api.expense.get_my_expenses');
    return asMapList(data).map(Expense.fromJson).toList();
  }

  Future<Expense> createExpense({
    required String title,
    required double amount,
    required DateTime expenseDate,
    required ExpenseCategory category,
    String? notes,
    bool submit = false,
  }) async {
    final params = <String, dynamic>{
      'title': title,
      'amount': amount,
      'expense_date': _dateOnly(expenseDate),
      'category': category.apiValue,
      'submit': submit ? 1 : 0,
    };
    if (notes != null && notes.trim().isNotEmpty) {
      params['notes'] = notes.trim();
    }
    final data = await _client.postMethod('zeus.api.expense.create_expense', params);
    final json = asMap(data);
    if (json == null) {
      throw const ApiException('Expense payload was missing');
    }
    return Expense.fromJson(json);
  }

  Future<Expense> submitExpense(String claimName) async {
    final data = await _client.postMethod('zeus.api.expense.submit_expense', {
      'claim_name': claimName,
    });
    final json = asMap(data);
    if (json == null) {
      throw const ApiException('Expense payload was missing');
    }
    return Expense.fromJson(json);
  }

  String _dateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
