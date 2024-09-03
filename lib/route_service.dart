import 'package:http/http.dart' as http;
import 'dart:convert';

class RouteService {
  final String apiKey = '5b3ce3597851110001cf6248e07514fe354d41618952e73e1b6fcea0'; // Remplacez par votre propre clé API

  Future<Map<String, dynamic>?> getRoute(List<List<double>> coordinates) async {
    final url = 'https://api.openrouteservice.org/v2/directions/driving-car';
    final body = json.encode({
      "coordinates": coordinates,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }
}
