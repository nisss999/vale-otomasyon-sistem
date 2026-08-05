import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  Future<LatLng?> getCurrentLocation({Function(String error)? onError}) async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          onError?.call('GPS / Konum servisleri kapalı.');
          if (kDebugMode) print('LocationService: GPS service disabled.');
          return null;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          onError?.call('Konum izni verilmedi.');
          if (kDebugMode) print('LocationService: Permission denied.');
          return null;
        }
      }

      if (permissionGranted == PermissionStatus.deniedForever) {
        onError?.call('Konum izni kalıcı olarak engellendi. Ayarlardan izin verin.');
        if (kDebugMode) print('LocationService: Permission denied forever.');
        return null;
      }

      final currentLocation = await _location.getLocation();
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        if (kDebugMode) {
          print('LocationService success: ${currentLocation.latitude}, ${currentLocation.longitude}');
        }
        return LatLng(currentLocation.latitude!, currentLocation.longitude!);
      }
    } catch (e) {
      onError?.call('Konum alınırken hata oluştu: $e');
      if (kDebugMode) print('LocationService error: $e');
    }
    return null;
  }
}
