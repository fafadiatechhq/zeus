import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard.dart';
import '../repositories/dashboard_repository.dart';
import 'api_providers.dart';

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardData>(DashboardNotifier.new);

class DashboardNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() => _load();

  Future<DashboardData> _load() async {
    final repo = DashboardRepository(await requireApiClient());
    return repo.getDashboard();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(_load);
  }
}
