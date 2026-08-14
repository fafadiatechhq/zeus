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
