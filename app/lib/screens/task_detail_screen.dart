import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../api/api_exception.dart';
import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/async_value_view.dart';
import 'tasks_screen.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _notesController = TextEditingController();
  bool _notesSeeded = false;
  bool _busy = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {bool popOnSuccess = false}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (popOnSuccess) {
        Navigator.pop(context);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppTheme.danger),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(taskDetailProvider(widget.taskId), (previous, next) {
      final loaded = next.valueOrNull;
      if (loaded != null && !_notesSeeded) {
        _notesController.text = loaded.completionNotes ?? '';
        _notesSeeded = true;
      }
    });
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));
    final task = taskAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          PopupMenuButton<TaskStatus>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            tooltip: 'Update Status',
            enabled: !_busy && task != null && task.status != TaskStatus.completed,
            onSelected: (status) {
              _run(
                () => ref.read(taskDetailProvider(widget.taskId).notifier).updateStatus(status),
                popOnSuccess: status == TaskStatus.completed,
              );
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: TaskStatus.open, child: Text('Mark as Open')),
              const PopupMenuItem(value: TaskStatus.inProgress, child: Text('Mark In Progress')),
              const PopupMenuItem(value: TaskStatus.completed, child: Text('Mark Completed')),
              const PopupMenuItem(value: TaskStatus.blocked, child: Text('Mark Blocked')),
            ],
          ),
        ],
      ),
      body: AsyncValueView(
        value: taskAsync,
        onRetry: () async => ref.invalidate(taskDetailProvider(widget.taskId)),
        builder: (task) {
          final isOverdue = task.dueDate.isBefore(DateTime.now()) && task.status != TaskStatus.completed;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _PriorityBadge(priority: task.priority),
                          const SizedBox(width: 8),
                          _StatusBadge(status: task.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(task.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(task.description,
                            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
                      ],
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Due',
                        value: DateFormat('d MMM yyyy, hh:mm a').format(task.dueDate),
                        valueColor: isOverdue ? AppTheme.danger : null,
                      ),
                      if (task.linkedCustomer != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(icon: Icons.business_outlined, label: 'Customer', value: task.linkedCustomer!),
                      ],
                      if (task.linkedSite != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(icon: Icons.location_on_outlined, label: 'Site', value: task.linkedSite!),
                      ],
                      if (task.requiresGeoVerification) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gps_fixed, size: 14, color: AppTheme.primary),
                              SizedBox(width: 6),
                              Text('Geo-verification required',
                                  style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (task.checklist.isNotEmpty) ...[
                const Text('Checklist',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: task.checklist.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Column(
                        children: [
                          InkWell(
                            onTap: _busy || task.status == TaskStatus.completed
                                ? null
                                : () => _run(
                                      () => ref
                                          .read(taskDetailProvider(widget.taskId).notifier)
                                          .toggleChecklist(item.id, !item.isDone),
                                    ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: item.isDone ? AppTheme.success : Colors.transparent,
                                      border: Border.all(
                                        color: item.isDone ? AppTheme.success : AppTheme.borderLight,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: item.isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: item.isDone ? AppTheme.textSubtle : AppTheme.textPrimary,
                                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (idx < task.checklist.length - 1) const Divider(height: 1, indent: 50),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text('Completion Notes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 4,
                enabled: !_busy && task.status != TaskStatus.completed,
                decoration: const InputDecoration(
                  hintText: 'Add notes about this task...',
                ),
              ),
              const SizedBox(height: 24),
              if (_busy)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (task.status != TaskStatus.completed)
                  ElevatedButton.icon(
                    onPressed: () => _run(
                      () => ref.read(taskDetailProvider(widget.taskId).notifier).complete(
                            notes: _notesController.text,
                          ),
                      popOnSuccess: true,
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as Completed'),
                  ),
                if (task.status == TaskStatus.open)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: OutlinedButton.icon(
                      onPressed: () => _run(
                        () => ref.read(taskDetailProvider(widget.taskId).notifier).updateStatus(TaskStatus.inProgress),
                      ),
                      icon: const Icon(Icons.play_arrow_outlined),
                      label: const Text('Start Task'),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSubtle),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppTheme.textSubtle)),
        Expanded(
          child: Text(value,
              style: TextStyle(fontSize: 13, color: valueColor ?? AppTheme.textPrimary, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (priority) {
      case TaskPriority.low:
        color = AppTheme.textMuted;
        label = 'Low';
        break;
      case TaskPriority.medium:
        color = AppTheme.warning;
        label = 'Medium';
        break;
      case TaskPriority.high:
        color = AppTheme.priorityHigh;
        label = 'High';
        break;
      case TaskPriority.urgent:
        color = AppTheme.danger;
        label = 'Urgent';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status.color)),
    );
  }
}
