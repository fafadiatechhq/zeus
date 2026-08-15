import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/json_util.dart';
import '../models/dashboard.dart';

class DashboardRepository {
  DashboardRepository(this._client);

  final ApiClient _client;

  Future<DashboardData> getDashboard() async {
    final data = await _client.postMethod('zeus.api.mobile.get_dashboard');
    final json = asMap(data);
    if (json == null) {
      throw const ApiException('Dashboard payload was missing');
    }
    return DashboardData.fromJson(json);
  }
}
