import '../api/json_util.dart';

enum ExpenseStatus { draft, submitted, approved, rejected }

enum ExpenseCategory { travel, food, accommodation, communication, equipment, other }

class Expense {
  final String id;
  final String userId;
  final String title;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final ExpenseStatus status;
  final String? linkedTaskId;
  final String? notes;
  final bool hasReceipt;

  const Expense({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.status,
    this.linkedTaskId,
    this.notes,
    this.hasReceipt = false,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final notes = asString(json['notes']);
    final linked = asString(json['linked_task']);
    return Expense(
      id: asString(json['name']),
      userId: asString(json['employee']),
      title: asString(json['title'], fallback: asString(json['name'])),
      category: expenseCategoryFromApi(asString(json['category'])),
      amount: asDouble(json['amount']),
      date: asDateTimeOrNow(json['date']),
      status: expenseStatusFromApi(asString(json['status'])),
      linkedTaskId: linked.isEmpty ? null : linked,
      notes: notes.isEmpty ? null : notes,
      hasReceipt: asBool(json['has_receipt']),
    );
  }
}

extension ExpenseCategoryLabel on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.food:
        return 'Food & Meals';
      case ExpenseCategory.accommodation:
        return 'Accommodation';
      case ExpenseCategory.communication:
        return 'Communication';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get apiValue {
    switch (this) {
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.accommodation:
        return 'Accommodation';
      case ExpenseCategory.communication:
        return 'Communication';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

ExpenseCategory expenseCategoryFromApi(String raw) {
  switch (raw.toLowerCase().replaceAll('&', 'and').replaceAll(RegExp(r'[\s_]+'), '')) {
    case 'travel':
      return ExpenseCategory.travel;
    case 'food':
    case 'foodandmeals':
      return ExpenseCategory.food;
    case 'accommodation':
      return ExpenseCategory.accommodation;
    case 'communication':
      return ExpenseCategory.communication;
    case 'equipment':
      return ExpenseCategory.equipment;
    default:
      return ExpenseCategory.other;
  }
}

ExpenseStatus expenseStatusFromApi(String raw) {
  switch (raw.toLowerCase()) {
    case 'submitted':
      return ExpenseStatus.submitted;
    case 'approved':
      return ExpenseStatus.approved;
    case 'rejected':
      return ExpenseStatus.rejected;
    default:
      return ExpenseStatus.draft;
  }
}
