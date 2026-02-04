// lib/core/services/nominatim_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';

/// Service for geocoding using self-hosted Nominatim
class NominatimService {
  static final NominatimService _instance = NominatimService._internal();
  factory NominatimService() => _instance;
  NominatimService._internal();

  final String _baseUrl = ApiConfig.nominatimUrl;

  /// Reverse geocode: coordinates to address
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'FROGIO-SantaJuana/1.0',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _formatAddress(data);
      }
    } catch (e) {
      log('Nominatim reverse geocode error: $e');
    }
    return null;
  }

  /// Forward geocode: address to coordinates
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      // Add Chile/Santa Juana context for better results
      final searchQuery = '$address, Santa Juana, Chile';
      final url = Uri.parse(
        '$_baseUrl/search?format=json&q=${Uri.encodeComponent(searchQuery)}&limit=1&addressdetails=1',
      );

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'FROGIO-SantaJuana/1.0',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final result = data.first;
          return LatLng(
            double.parse(result['lat']),
            double.parse(result['lon']),
          );
        }
      }
    } catch (e) {
      log('Nominatim forward geocode error: $e');
    }
    return null;
  }

  /// Search for places with autocomplete
  Future<List<NominatimPlace>> searchPlaces(String query, {int limit = 5}) async {
    try {
      final searchQuery = '$query, Chile';
      final url = Uri.parse(
        '$_baseUrl/search?format=json&q=${Uri.encodeComponent(searchQuery)}&limit=$limit&addressdetails=1',
      );

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'FROGIO-SantaJuana/1.0',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => NominatimPlace.fromJson(item)).toList();
      }
    } catch (e) {
      log('Nominatim search error: $e');
    }
    return [];
  }

  String? _formatAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return data['display_name'] as String?;

    final parts = <String>[];

    // Street + house number
    final road = address['road'] ?? address['street'];
    final houseNumber = address['house_number'];
    if (road != null) {
      parts.add(houseNumber != null ? '$road $houseNumber' : road);
    }

    // Neighborhood/suburb
    final suburb = address['suburb'] ?? address['neighbourhood'] ?? address['residential'];
    if (suburb != null && suburb != road) parts.add(suburb);

    // City
    final city = address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'];
    if (city != null) parts.add(city);

    if (parts.isEmpty) return data['display_name'] as String?;
    return parts.join(', ');
  }
}

/// Place result from Nominatim
class NominatimPlace {
  final String displayName;
  final double lat;
  final double lon;
  final String? type;
  final Map<String, dynamic>? address;

  NominatimPlace({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.type,
    this.address,
  });

  factory NominatimPlace.fromJson(Map<String, dynamic> json) {
    return NominatimPlace(
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat'].toString()),
      lon: double.parse(json['lon'].toString()),
      type: json['type'],
      address: json['address'],
    );
  }

  LatLng get latLng => LatLng(lat, lon);
}
