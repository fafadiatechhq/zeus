import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/expenses_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/async_value_view.dart';
import 'expense_form_screen.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseFormScreen()));
    ref.invalidate(expensesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context, ref),
          ),
        ],
      ),
      body: AsyncValueView(
        value: expensesAsync,
        onRetry: () => ref.read(expensesProvider.notifier).reload(),
        builder: (expenses) {
          final totalPending = expenses
              .where((e) => e.status == ExpenseStatus.draft || e.status == ExpenseStatus.submitted)
              .fold(0.0, (sum, e) => sum + e.amount);

          return RefreshIndicator(
            onRefresh: () => ref.read(expensesProvider.notifier).reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: AppTheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pending Approval', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(totalPending),
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('This Month', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                                  .format(expenses.fold(0.0, (s, e) => s + e.amount)),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Recent Expenses',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                if (expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No expenses yet', style: TextStyle(color: AppTheme.textSubtle)),
                    ),
                  )
                else
                  ...expenses.map(
                    (expense) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ExpenseTile(expense: expense),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;

  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(expense.status);
    final statusLabel = _statusLabel(expense.status);
    final categoryIcon = _categoryIcon(expense.category);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(categoryIcon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(expense.category.label, style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle)),
                      const Text(' · ', style: TextStyle(color: AppTheme.textSubtle)),
                      Text(DateFormat('d MMM').format(expense.date),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle)),
                      if (expense.hasReceipt) ...[
                        const Text(' · ', style: TextStyle(color: AppTheme.textSubtle)),
                        const Icon(Icons.receipt_outlined, size: 11, color: AppTheme.textSubtle),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(expense.amount),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ExpenseStatus s) {
    switch (s) {
      case ExpenseStatus.approved:
        return AppTheme.success;
      case ExpenseStatus.rejected:
        return AppTheme.danger;
      case ExpenseStatus.submitted:
        return AppTheme.primary;
      default:
        return AppTheme.textSubtle;
    }
  }

  String _statusLabel(ExpenseStatus s) {
    switch (s) {
      case ExpenseStatus.draft:
        return 'Draft';
      case ExpenseStatus.submitted:
        return 'Submitted';
      case ExpenseStatus.approved:
        return 'Approved';
      case ExpenseStatus.rejected:
        return 'Rejected';
    }
  }

  IconData _categoryIcon(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.travel:
        return Icons.directions_car_outlined;
      case ExpenseCategory.food:
        return Icons.restaurant_outlined;
      case ExpenseCategory.accommodation:
        return Icons.hotel_outlined;
      case ExpenseCategory.communication:
        return Icons.phone_outlined;
      case ExpenseCategory.equipment:
        return Icons.build_outlined;
      case ExpenseCategory.other:
        return Icons.category_outlined;
    }
  }
}
