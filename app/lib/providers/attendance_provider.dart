import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance.dart';
import '../repositories/attendance_repository.dart';
import '../services/location_service.dart';
import 'api_providers.dart';
import 'dashboard_provider.dart';

final attendanceProvider =
    AsyncNotifierProvider<AttendanceNotifier, AttendanceSnapshot>(AttendanceNotifier.new);

final monthlySummaryProvider = AsyncNotifierProvider<MonthlySummaryNotifier, MonthlySummary>(
  MonthlySummaryNotifier.new,
);

class AttendanceNotifier extends AsyncNotifier<AttendanceSnapshot> {
  @override
  Future<AttendanceSnapshot> build() => _load();

  Future<AttendanceSnapshot> _load() async {
    final repo = AttendanceRepository(await requireApiClient());
    final today = await repo.getToday();
    final history = await repo.getHistory();
    final monthly = await repo.getMonthlySummary();
    return AttendanceSnapshot(today: today, history: history, monthly: monthly);
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(_load);
  }

  Future<void> checkIn() async {
    final position = await LocationService.currentPosition();
    final repo = AttendanceRepository(await requireApiClient());
    await repo.checkIn(position.latitude, position.longitude);
    ref.invalidate(dashboardProvider);
    ref.invalidate(monthlySummaryProvider);
    state = await AsyncValue.guard(_load);
  }

  Future<void> checkOut() async {
    final position = await LocationService.currentPosition();
    final repo = AttendanceRepository(await requireApiClient());
    await repo.checkOut(position.latitude, position.longitude);
    ref.invalidate(dashboardProvider);
    ref.invalidate(monthlySummaryProvider);
    state = await AsyncValue.guard(_load);
  }
}

class MonthlySummaryNotifier extends AsyncNotifier<MonthlySummary> {
  @override
  Future<MonthlySummary> build() => _load();

  Future<MonthlySummary> _load() async {
    final repo = AttendanceRepository(await requireApiClient());
    return repo.getMonthlySummary();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(_load);
  }
}
