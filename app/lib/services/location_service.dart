import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../api/api_exception.dart';

class GeoPosition {
  const GeoPosition({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  String get label => '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
}

class LocationService {
  LocationService._();

  static Future<GeoPosition> currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const ApiException('Location services are turned off. Enable GPS and try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const ApiException('Location permission is required for this action.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const ApiException('Location permission is denied. Enable it in Settings.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return GeoPosition(latitude: position.latitude, longitude: position.longitude);
    } on TimeoutException {
      throw const ApiException('Could not get GPS location. Try again outdoors.');
    } on LocationServiceDisabledException {
      throw const ApiException('Location services are turned off. Enable GPS and try again.');
    }
  }
}
