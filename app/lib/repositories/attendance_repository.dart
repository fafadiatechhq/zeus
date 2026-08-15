import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/json_util.dart';
import '../models/attendance.dart';

class AttendanceRepository {
  AttendanceRepository(this._client);

  final ApiClient _client;

  Future<AttendanceRecord> getToday() async {
    final data = await _client.postMethod('zeus.api.attendance.get_today_attendance');
    final json = asMap(data);
    if (json == null) {
      throw const ApiException('Today attendance payload was missing');
    }
    return AttendanceRecord.fromToday(json);
  }

  Future<AttendanceRecord> checkIn(double latitude, double longitude) async {
    final data = await _client.postMethod('zeus.api.attendance.checkin', {
      'latitude': latitude,
      'longitude': longitude,
    });
    final json = asMap(data);
    if (json == null) {
      throw const ApiException('Check-in payload was missing');
    }
    return AttendanceRecord.fromToday(json);
  }

  Future<AttendanceRecord> checkOut(double latitude, double longitude) async {
    final data = await _client.postMethod('zeus.api.attendance.checkout', {
      'latitude': latitude,
      'longitude': longitude,
    });
    final json = asMap(data);
    if (json == null) {
      throw const ApiException('Check-out payload was missing');
    }
    return AttendanceRecord.fromToday(json);
  }

  Future<List<AttendanceRecord>> getHistory() async {
    final data = await _client.postMethod('zeus.api.attendance.get_attendance_history');
    return asMapList(data).map(AttendanceRecord.fromHistory).toList();
  }

  Future<MonthlySummary> getMonthlySummary() async {
    final data = await _client.postMethod('zeus.api.attendance.get_monthly_summary');
    final json = asMap(data);
    if (json == null) {
      throw const ApiException('Monthly summary payload was missing');
    }
    return MonthlySummary.fromJson(json);
  }
}
