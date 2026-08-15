import 'dart:convert';

import 'package:dio/dio.dart';

/// User-facing failure from a Frappe Method / Resource API call.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.excType});

  final String message;
  final int? statusCode;
  final String? excType;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    if (response != null) {
      return ApiException.fromResponse(response);
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('Connection timed out. Check that ERPNext is running.');
      case DioExceptionType.connectionError:
        return const ApiException('Could not reach the server. Check your network and API URL.');
      default:
        return ApiException(error.message ?? 'Request failed');
    }
  }

  factory ApiException.fromResponse(Response response) {
    final data = response.data;
    String? excType;
    var message = 'Request failed (${response.statusCode})';

    if (data is Map) {
      excType = data['exc_type'] as String?;
      final parsed = _serverMessages(data['_server_messages']);
      if (parsed != null && parsed.isNotEmpty) {
        message = parsed;
      } else if (data['exception'] is String && (data['exception'] as String).isNotEmpty) {
        message = data['exception'] as String;
      } else if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        message = data['message'] as String;
      }
    }

    return ApiException(message, statusCode: response.statusCode, excType: excType);
  }

  static String? _serverMessages(dynamic raw) {
    if (raw == null) {
      return null;
    }
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! List) {
        return raw.toString();
      }
      final parts = <String>[];
      for (final item in decoded) {
        dynamic message = item;
        if (item is String) {
          try {
            message = jsonDecode(item);
          } catch (_) {
            parts.add(item);
            continue;
          }
        }
        if (message is Map && message['message'] != null) {
          parts.add(message['message'].toString());
        } else if (message is String) {
          parts.add(message);
        }
      }
      if (parts.isEmpty) {
        return null;
      }
      return parts.join('\n');
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  String toString() => message;
}
