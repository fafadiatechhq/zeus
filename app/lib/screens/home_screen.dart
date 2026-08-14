import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import '../models/attendance.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;
    final stats = MockData.dashboardStats;
    final attendance = MockData.todayAttendance;
    final upcomingTasks = MockData.tasks
        .where((t) => t.status == TaskStatus.open || t.status == TaskStatus.inProgress)
        .take(3)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good ${_greeting()}, ${user.name.split(' ').first}'),
            Text(
              DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
              style: const TextStyle(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(user.avatarInitials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Attendance status banner
          _AttendanceBanner(attendance: attendance),
          const SizedBox(height: 20),

          // Stats row
          const Text('Today\'s Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Open Tasks',
                  value: '${stats['tasksToday']}',
                  icon: Icons.task_alt,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Completed',
                  value: '${stats['tasksCompleted']}',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Expenses',
                  value: '${stats['pendingExpenses']}',
                  icon: Icons.receipt_long_outlined,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Upcoming tasks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Tasks', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              TextButton(onPressed: () {}, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: 8),
          if (upcomingTasks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No upcoming tasks', style: TextStyle(color: AppTheme.textSubtle)),
              ),
            )
          else
            ...upcomingTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TaskCard(task: task),
                )),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _AttendanceBanner extends StatelessWidget {
  final AttendanceRecord attendance;

  const _AttendanceBanner({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = attendance.status == AttendanceStatus.checkedIn;
    final isCheckedOut = attendance.status == AttendanceStatus.checkedOut;

    Color bgColor;
    IconData icon;
    String title;
    String subtitle;

    if (isCheckedIn) {
      bgColor = AppTheme.success;
      icon = Icons.location_on;
      title = 'Checked In';
      subtitle = attendance.checkInTime != null
          ? 'Since ${DateFormat('hh:mm a').format(attendance.checkInTime!)} · ${attendance.checkInLocation ?? ''}'
          : '';
    } else if (isCheckedOut) {
      bgColor = AppTheme.primaryDark;
      icon = Icons.logout;
      title = 'Checked Out';
      subtitle = attendance.checkOutTime != null
          ? 'At ${DateFormat('hh:mm a').format(attendance.checkOutTime!)} · ${attendance.checkOutLocation ?? ''}'
          : '';
    } else if (attendance.status == AttendanceStatus.onLeave) {
      bgColor = AppTheme.warning;
      icon = Icons.beach_access_outlined;
      title = 'On Leave';
      subtitle = 'Approved leave for today';
    } else {
      bgColor = AppTheme.textSecondary;
      icon = Icons.touch_app_outlined;
      title = 'Not Checked In';
      subtitle = 'Tap Attendance to check in';
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
