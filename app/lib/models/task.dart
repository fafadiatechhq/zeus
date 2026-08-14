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

  ChecklistItem copyWith({bool? isDone}) {
    return ChecklistItem(id: id, label: label, isDone: isDone ?? this.isDone);
  }
}
