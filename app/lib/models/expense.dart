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
}
