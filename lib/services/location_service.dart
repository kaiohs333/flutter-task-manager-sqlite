import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService instance = LocationService._init();
  LocationService._init();

  // 1. Verifica e Pede Permissão de Localização
  Future<bool> checkAndRequestPermission() async {
    // Verifica se o serviço de localização (GPS) está ligado no celular
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ Serviço de localização desabilitado');
      return false;
    }

    // Verifica a permissão atual do app
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Se negada, pede permissão
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('⚠️ Permissão negada');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Se negada permanentemente, não podemos pedir de novo
      print('⚠️ Permissão negada permanentemente');
      return false;
    }

    print('✅ Permissão de localização concedida');
    return true;
  }

  // 2. Obtém a Posição Atual (GPS)
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      // Pega a localização com alta precisão
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('❌ Erro ao obter localização: $e');
      return null;
    }
  }

  // 3. Converte Coordenadas em Endereço (Reverse Geocoding)
  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      // Busca o endereço a partir das coordenadas
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Formata o endereço de forma legível
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((p) => p != null && p.isNotEmpty).take(3); // Pega as 3 partes principais

        return parts.join(', ');
      }
    } catch (e) {
      print('❌ Erro ao obter endereço: $e');
    }
    return null;
  }

  // 4. Converte Endereço em Coordenadas (Geocoding)
  Future<Position?> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    } catch (e) {
      print('❌ Erro ao buscar endereço: $e');
    }
    return null;
  }
  
  // 5. Função Combinada: Pega GPS e Endereço de uma vez
  Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return null;

      final address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return {
        'position': position,
        'address': address ?? 'Endereço não disponível',
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('❌ Erro: $e');
      return null;
    }
  }

  // --- Funções Auxiliares ---

  double calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  String formatCoordinates(double lat, double lon) {
    return '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }
}