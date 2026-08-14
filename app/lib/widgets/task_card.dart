import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.dueDate.isBefore(DateTime.now()) && task.status != TaskStatus.completed;
    final doneCount = task.checklist.where((c) => c.isDone).length;
    final totalCount = task.checklist.length;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PriorityDot(priority: task.priority),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: task.status),
                ],
              ),
              if (task.linkedCustomer != null || task.linkedSite != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textSubtle),
                    const SizedBox(width: 4),
                    Text(
                      task.linkedCustomer ?? task.linkedSite ?? '',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 13,
                    color: isOverdue ? AppTheme.danger : AppTheme.textSubtle,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _dueLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? AppTheme.danger : AppTheme.textMuted,
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (totalCount > 0) ...[
                    const Spacer(),
                    Text(
                      '$doneCount/$totalCount done',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSubtle),
                    ),
                  ],
                ],
              ),
              if (totalCount > 0) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalCount > 0 ? doneCount / totalCount : 0,
                    backgroundColor: AppTheme.divider,
                    color: AppTheme.success,
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _dueLabel() {
    final now = DateTime.now();
    final diff = task.dueDate.difference(now);

    if (diff.isNegative) {
      final absDiff = diff.abs();
      if (absDiff.inDays > 0) return 'Overdue by ${absDiff.inDays}d';
      if (absDiff.inHours > 0) return 'Overdue by ${absDiff.inHours}h';
      return 'Just overdue';
    }

    if (diff.inDays == 0) {
      if (diff.inHours == 0) return 'Due in <1h';
      return 'Due in ${diff.inHours}h';
    }
    if (diff.inDays == 1) return 'Due tomorrow';
    return 'Due ${DateFormat('d MMM').format(task.dueDate)}';
  }
}

class _PriorityDot extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TaskPriority.low    => AppTheme.priorityLow,
      TaskPriority.medium => AppTheme.priorityMedium,
      TaskPriority.high   => AppTheme.priorityHigh,
      TaskPriority.urgent => AppTheme.priorityUrgent,
    };
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;

  const _StatusBadge({required this.status});

  Color get _color => switch (status) {
    TaskStatus.open       => AppTheme.primary,
    TaskStatus.inProgress => AppTheme.warning,
    TaskStatus.completed  => AppTheme.success,
    TaskStatus.blocked    => AppTheme.danger,
  };

  String get _label => switch (status) {
    TaskStatus.open       => 'Open',
    TaskStatus.inProgress => 'In Progress',
    TaskStatus.completed  => 'Done',
    TaskStatus.blocked    => 'Blocked',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(_label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _color)),
    );
  }
}
