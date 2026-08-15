import '../api/json_util.dart';
import 'attendance.dart';
import 'task.dart';

class DashboardData {
  final AttendanceRecord attendance;
  final int openTaskCount;
  final int completedTaskCount;
  final int pendingExpenseCount;
  final List<TaskItem> openTasks;

  const DashboardData({
    required this.attendance,
    required this.openTaskCount,
    required this.completedTaskCount,
    required this.pendingExpenseCount,
    required this.openTasks,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final attendance = asMap(json['attendance']);
    return DashboardData(
      attendance: attendance == null
          ? AttendanceRecord(
              id: 'today',
              userId: asString(json['employee']),
              date: asDateTimeOrNow(json['date']),
              status: AttendanceStatus.notCheckedIn,
            )
          : AttendanceRecord.fromToday(attendance),
      openTaskCount: asInt(json['open_task_count']),
      completedTaskCount: asInt(json['completed_task_count']),
      pendingExpenseCount: asInt(json['pending_expense_count']),
      openTasks: asMapList(json['open_tasks']).map(TaskItem.fromJson).toList(),
    );
  }
}
