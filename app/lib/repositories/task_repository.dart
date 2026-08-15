import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/json_util.dart';
import '../models/task.dart';

class TaskRepository {
  TaskRepository(this._client);

  final ApiClient _client;

  Future<List<TaskItem>> getMyTasks() async {
    final data = await _client.postMethod('zeus.api.task.get_my_tasks');
    return asMapList(data).map(TaskItem.fromJson).toList();
  }

  Future<TaskItem> getTask(String taskName) async {
    final data = await _client.postMethod('zeus.api.task.get_task', {
      'task_name': taskName,
    });
    final json = asMap(data);
    if (json == null) {
      throw const ApiException('Task payload was missing');
    }
    return TaskItem.fromJson(json);
  }

  Future<TaskItem> updateStatus(String taskName, TaskStatus status) async {
    final data = await _client.postMethod('zeus.api.task.update_task_status', {
      'task_name': taskName,
      'status': taskStatusToApi(status),
    });
    final json = asMap(data);
    if (json == null) {
      throw const ApiException('Task payload was missing');
    }
    return TaskItem.fromJson(json);
  }

  Future<TaskItem> updateChecklistItem(String taskName, String itemName, bool isDone) async {
    final data = await _client.postMethod('zeus.api.task.update_checklist_item', {
      'task_name': taskName,
      'item_name': itemName,
      'is_done': isDone ? 1 : 0,
    });
    final json = asMap(data);
    if (json == null) {
      throw const ApiException('Task payload was missing');
    }
    return TaskItem.fromJson(json);
  }

  Future<TaskItem> completeTask(
    String taskName, {
    double? latitude,
    double? longitude,
    String? completionNotes,
  }) async {
    final params = <String, dynamic>{'task_name': taskName};
    if (latitude != null) {
      params['latitude'] = latitude;
    }
    if (longitude != null) {
      params['longitude'] = longitude;
    }
    if (completionNotes != null && completionNotes.trim().isNotEmpty) {
      params['completion_notes'] = completionNotes.trim();
    }
    final data = await _client.postMethod('zeus.api.task.complete_task', params);
    final json = asMap(data);
    if (json == null) {
      throw const ApiException('Task payload was missing');
    }
    return TaskItem.fromJson(json);
  }
}
