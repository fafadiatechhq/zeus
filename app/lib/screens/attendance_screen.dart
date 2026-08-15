import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../api/api_exception.dart';
import '../models/attendance.dart';
import '../providers/attendance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/async_value_view.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _isLoading = false;

  Future<void> _runAction(Future<void> Function() action, String successMessage, Color color) async {
    setState(() => _isLoading = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: color),
      );
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendance = ref.watch(attendanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: AsyncValueView(
        value: attendance,
        onRetry: () => ref.read(attendanceProvider.notifier).reload(),
        builder: (data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(attendanceProvider.notifier).reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TodayCard(
                  record: data.today,
                  isLoading: _isLoading,
                  onCheckIn: () => _runAction(
                    () => ref.read(attendanceProvider.notifier).checkIn(),
                    'Checked in successfully',
                    AppTheme.success,
                  ),
                  onCheckOut: () => _runAction(
                    () => ref.read(attendanceProvider.notifier).checkOut(),
                    'Checked out successfully',
                    AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 24),
                _MonthSummaryCard(summary: data.monthly),
                const SizedBox(height: 24),
                const Text('Recent History',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                if (data.history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No attendance history yet', style: TextStyle(color: AppTheme.textSubtle)),
                    ),
                  )
                else
                  ...data.history.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HistoryTile(record: record),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final AttendanceRecord record;
  final bool isLoading;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const _TodayCard({
    required this.record,
    required this.isLoading,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    final notCheckedIn = record.status == AttendanceStatus.notCheckedIn;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, d MMM').format(DateTime.now()),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                _StatusChip(status: record.status),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _TimeBox(
                    label: 'Check In',
                    time: record.checkInTime != null ? DateFormat('hh:mm a').format(record.checkInTime!) : '--:--',
                    location: record.checkInLocation,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeBox(
                    label: 'Check Out',
                    time: record.checkOutTime != null ? DateFormat('hh:mm a').format(record.checkOutTime!) : '--:--',
                    location: record.checkOutLocation,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (notCheckedIn)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCheckIn,
                  icon: const Icon(Icons.location_on),
                  label: const Text('Check In'),
                ),
              )
            else if (record.status != AttendanceStatus.checkedOut && record.status != AttendanceStatus.onLeave)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCheckOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Check Out'),
                ),
              )
            else
              const Center(
                child: Text('Day complete', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String time;
  final String? location;
  final Color color;

  const _TimeBox({required this.label, required this.time, this.location, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          if (location != null) ...[
            const SizedBox(height: 4),
            Text(location!, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AttendanceStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case AttendanceStatus.checkedIn:
        color = AppTheme.success;
        label = 'Checked In';
        break;
      case AttendanceStatus.checkedOut:
        color = AppTheme.primaryDark;
        label = 'Checked Out';
        break;
      case AttendanceStatus.onLeave:
        color = AppTheme.warning;
        label = 'On Leave';
        break;
      case AttendanceStatus.absent:
        color = AppTheme.danger;
        label = 'Absent';
        break;
      default:
        color = AppTheme.textSubtle;
        label = 'Not Started';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({required this.summary});

  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _SummaryTile(label: 'Present', value: '${summary.present}', color: AppTheme.success),
                _SummaryTile(label: 'Absent', value: '${summary.absent}', color: AppTheme.danger),
                _SummaryTile(label: 'Leave', value: '${summary.leave}', color: AppTheme.warning),
                _SummaryTile(label: 'Working Days', value: '${summary.workingDays}', color: AppTheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final AttendanceRecord record;

  const _HistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (record.status) {
      case AttendanceStatus.checkedOut:
        statusColor = AppTheme.success;
        statusLabel = 'Present';
        break;
      case AttendanceStatus.checkedIn:
        statusColor = AppTheme.primary;
        statusLabel = 'Checked In';
        break;
      case AttendanceStatus.onLeave:
        statusColor = AppTheme.warning;
        statusLabel = 'On Leave';
        break;
      case AttendanceStatus.absent:
        statusColor = AppTheme.danger;
        statusLabel = 'Absent';
        break;
      default:
        statusColor = AppTheme.textSubtle;
        statusLabel = 'Unknown';
    }

    String duration = '';
    if (record.checkInTime != null && record.checkOutTime != null) {
      final diff = record.checkOutTime!.difference(record.checkInTime!);
      duration = '${diff.inHours}h ${diff.inMinutes % 60}m';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  DateFormat('d').format(record.date),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: statusColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('EEEE, d MMM').format(record.date),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  if (record.checkInTime != null)
                    Text(
                      '${DateFormat('hh:mm a').format(record.checkInTime!)} → ${record.checkOutTime != null ? DateFormat('hh:mm a').format(record.checkOutTime!) : '...'}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                ),
                if (duration.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(duration, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
