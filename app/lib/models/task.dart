import '../api/json_util.dart';

enum TaskStatus { open, inProgress, completed, blocked }

enum TaskPriority { low, medium, high, urgent }

class TaskItem {
  final String id;
  final String title;
  final String description;
  final String assigneeId;
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final String? linkedCustomer;
  final String? linkedSite;
  final List<ChecklistItem> checklist;
  final String? completionNotes;
  final bool requiresGeoVerification;

  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.dueDate,
    required this.status,
    required this.priority,
    this.linkedCustomer,
    this.linkedSite,
    this.checklist = const [],
    this.completionNotes,
    this.requiresGeoVerification = false,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final customer = asString(json['customer']);
    final site = asString(json['site']);
    final notes = asString(json['completion_notes']);
    return TaskItem(
      id: asString(json['name']),
      title: asString(json['title']),
      description: stripHtml(asString(json['description'])),
      assigneeId: asString(json['assigned_to']),
      dueDate: asDateTimeOrNow(json['due_date']),
      status: taskStatusFromApi(asString(json['status'])),
      priority: taskPriorityFromApi(asString(json['priority'])),
      linkedCustomer: customer.isEmpty ? null : customer,
      linkedSite: site.isEmpty ? null : site,
      checklist: asMapList(json['checklist']).map(ChecklistItem.fromJson).toList(),
      completionNotes: notes.isEmpty ? null : notes,
      requiresGeoVerification: asBool(json['requires_geo_verification']),
    );
  }

  TaskItem copyWith({TaskStatus? status, String? completionNotes, List<ChecklistItem>? checklist}) {
    return TaskItem(
      id: id,
      title: title,
      description: description,
      assigneeId: assigneeId,
      dueDate: dueDate,
      status: status ?? this.status,
      priority: priority,
      linkedCustomer: linkedCustomer,
      linkedSite: linkedSite,
      checklist: checklist ?? this.checklist,
      completionNotes: completionNotes ?? this.completionNotes,
      requiresGeoVerification: requiresGeoVerification,
    );
  }
}

class ChecklistItem {
  final String id;
  final String label;
  final bool isDone;

  const ChecklistItem({required this.id, required this.label, this.isDone = false});

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: asString(json['name']),
      label: asString(json['label']),
      isDone: asBool(json['is_done']),
    );
  }

  ChecklistItem copyWith({bool? isDone}) {
    return ChecklistItem(id: id, label: label, isDone: isDone ?? this.isDone);
  }
}

TaskStatus taskStatusFromApi(String raw) {
  switch (raw.toLowerCase().replaceAll('_', ' ')) {
    case 'in progress':
      return TaskStatus.inProgress;
    case 'completed':
      return TaskStatus.completed;
    case 'blocked':
      return TaskStatus.blocked;
    default:
      return TaskStatus.open;
  }
}

String taskStatusToApi(TaskStatus status) {
  switch (status) {
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

TaskPriority taskPriorityFromApi(String raw) {
  switch (raw.toLowerCase()) {
    case 'low':
      return TaskPriority.low;
    case 'high':
      return TaskPriority.high;
    case 'urgent':
      return TaskPriority.urgent;
    default:
      return TaskPriority.medium;
  }
}
