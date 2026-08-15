import '../api/json_util.dart';

enum AttendanceStatus { notCheckedIn, checkedIn, checkedOut, onLeave, absent }

class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? checkInTime;
  final String? checkInLocation;
  final DateTime? checkOutTime;
  final String? checkOutLocation;
  final AttendanceStatus status;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    this.checkInTime,
    this.checkInLocation,
    this.checkOutTime,
    this.checkOutLocation,
    required this.status,
  });

  factory AttendanceRecord.fromToday(Map<String, dynamic> json) {
    final checkIn = asMap(json['check_in']);
    final checkOut = asMap(json['check_out']);
    final attendance = asMap(json['attendance']);
    return AttendanceRecord(
      id: asString(attendance?['name'], fallback: 'today'),
      userId: asString(json['employee']),
      date: asDateTimeOrNow(json['date']),
      checkInTime: asDateTime(checkIn?['time']),
      checkInLocation: formatCoords(checkIn?['latitude'], checkIn?['longitude']),
      checkOutTime: asDateTime(checkOut?['time']),
      checkOutLocation: formatCoords(checkOut?['latitude'], checkOut?['longitude']),
      status: attendanceStatusFromApi(asString(json['status'])),
    );
  }

  factory AttendanceRecord.fromHistory(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: asString(json['name'], fallback: asString(json['date'])),
      userId: '',
      date: asDateTimeOrNow(json['date']),
      checkInTime: asDateTime(json['check_in_time']),
      checkOutTime: asDateTime(json['check_out_time']),
      status: attendanceStatusFromApi(asString(json['status'])),
    );
  }

  AttendanceRecord copyWith({
    DateTime? checkInTime,
    String? checkInLocation,
    DateTime? checkOutTime,
    String? checkOutLocation,
    AttendanceStatus? status,
  }) {
    return AttendanceRecord(
      id: id,
      userId: userId,
      date: date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      status: status ?? this.status,
    );
  }
}

class MonthlySummary {
  final int present;
  final int absent;
  final int leave;
  final int workingDays;

  const MonthlySummary({
    this.present = 0,
    this.absent = 0,
    this.leave = 0,
    this.workingDays = 0,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      present: asInt(json['present']),
      absent: asInt(json['absent']),
      leave: asInt(json['leave']),
      workingDays: asInt(json['working_days']),
    );
  }
}

class AttendanceSnapshot {
  final AttendanceRecord today;
  final List<AttendanceRecord> history;
  final MonthlySummary monthly;

  const AttendanceSnapshot({
    required this.today,
    required this.history,
    required this.monthly,
  });

  AttendanceSnapshot copyWith({
    AttendanceRecord? today,
    List<AttendanceRecord>? history,
    MonthlySummary? monthly,
  }) {
    return AttendanceSnapshot(
      today: today ?? this.today,
      history: history ?? this.history,
      monthly: monthly ?? this.monthly,
    );
  }
}

AttendanceStatus attendanceStatusFromApi(String raw) {
  switch (raw.toLowerCase().replaceAll(' ', '_')) {
    case 'checked_in':
      return AttendanceStatus.checkedIn;
    case 'checked_out':
    case 'present':
      return AttendanceStatus.checkedOut;
    case 'on_leave':
      return AttendanceStatus.onLeave;
    case 'absent':
      return AttendanceStatus.absent;
    default:
      return AttendanceStatus.notCheckedIn;
  }
}
