import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/async_value_view.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Open', 'In Progress', 'Completed', 'Blocked'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TaskItem> _filtered(List<TaskItem> tasks, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return tasks.where((t) => t.status == TaskStatus.open).toList();
      case 2:
        return tasks.where((t) => t.status == TaskStatus.inProgress).toList();
      case 3:
        return tasks.where((t) => t.status == TaskStatus.completed).toList();
      case 4:
        return tasks.where((t) => t.status == TaskStatus.blocked).toList();
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.accent,
          indicatorColor: Colors.white,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: AsyncValueView(
        value: tasksAsync,
        onRetry: () => ref.read(tasksProvider.notifier).reload(),
        builder: (tasks) {
          return TabBarView(
            controller: _tabController,
            children: List.generate(_tabs.length, (i) {
              final filtered = _filtered(tasks, i);
              if (filtered.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => ref.read(tasksProvider.notifier).reload(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.task_outlined, size: 48, color: AppTheme.borderLight),
                            SizedBox(height: 12),
                            Text('No tasks here', style: TextStyle(color: AppTheme.textSubtle)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(tasksProvider.notifier).reload(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => TaskCard(
                    task: filtered[index],
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: filtered[index].id)),
                      );
                      ref.invalidate(tasksProvider);
                    },
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

extension TaskStatusBadge on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.open:
        return 'Open';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.blocked:
        return 'Blocked';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.open:
        return AppTheme.primary;
      case TaskStatus.inProgress:
        return AppTheme.warning;
      case TaskStatus.completed:
        return AppTheme.success;
      case TaskStatus.blocked:
        return AppTheme.danger;
    }
  }
}
