Map<String, dynamic>? asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value.map(asMap).whereType<Map<String, dynamic>>().toList();
}

String asString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int asInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final text = value?.toString().toLowerCase();
  return text == '1' || text == 'true' || text == 'yes';
}

DateTime? asDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text.replaceFirst(' ', 'T'));
}

DateTime asDateTimeOrNow(dynamic value) => asDateTime(value) ?? DateTime.now();

String? formatCoords(dynamic latitude, dynamic longitude) {
  if (latitude == null || longitude == null) {
    return null;
  }
  final lat = double.tryParse(latitude.toString());
  final lng = double.tryParse(longitude.toString());
  if (lat == null || lng == null) {
    return null;
  }
  return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}

String stripHtml(String raw) {
  return raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .trim();
}
