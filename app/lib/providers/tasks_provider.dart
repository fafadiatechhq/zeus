import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../services/location_service.dart';
import 'api_providers.dart';
import 'dashboard_provider.dart';

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<TaskItem>>(TasksNotifier.new);

final taskDetailProvider =
    AsyncNotifierProvider.family<TaskDetailNotifier, TaskItem, String>(
  TaskDetailNotifier.new,
);

class TasksNotifier extends AsyncNotifier<List<TaskItem>> {
  @override
  Future<List<TaskItem>> build() => _load();

  Future<List<TaskItem>> _load() async {
    final repo = TaskRepository(await requireApiClient());
    return repo.getMyTasks();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(_load);
  }
}

class TaskDetailNotifier extends FamilyAsyncNotifier<TaskItem, String> {
  @override
  Future<TaskItem> build(String arg) async {
    final repo = TaskRepository(await requireApiClient());
    return repo.getTask(arg);
  }

  Future<void> updateStatus(TaskStatus status) async {
    if (status == TaskStatus.completed) {
      await complete();
      return;
    }
    final repo = TaskRepository(await requireApiClient());
    final updated = await repo.updateStatus(arg, status);
    state = AsyncData(updated);
    ref.invalidate(tasksProvider);
    ref.invalidate(dashboardProvider);
  }

  Future<void> toggleChecklist(String itemName, bool isDone) async {
    final repo = TaskRepository(await requireApiClient());
    final updated = await repo.updateChecklistItem(arg, itemName, isDone);
    state = AsyncData(updated);
    ref.invalidate(tasksProvider);
    ref.invalidate(dashboardProvider);
  }

  Future<void> complete({String? notes}) async {
    final current = state.valueOrNull;
    double? latitude;
    double? longitude;
    if (current?.requiresGeoVerification == true) {
      final position = await LocationService.currentPosition();
      latitude = position.latitude;
      longitude = position.longitude;
    }
    final repo = TaskRepository(await requireApiClient());
    final updated = await repo.completeTask(
      arg,
      latitude: latitude,
      longitude: longitude,
      completionNotes: notes,
    );
    state = AsyncData(updated);
    ref.invalidate(tasksProvider);
    ref.invalidate(dashboardProvider);
  }
}
