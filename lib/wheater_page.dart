import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  List<Map<String, dynamic>> _forecastData = [];
  String _weatherAlert = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    const apiKey = 'c3d495d7666f1b1bfbdfdb17c883db1b'; // Remplace par ta clé API

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final latitude = position.latitude;
      final longitude = position.longitude;

      final url = 'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric&lang=fr';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['list'];

        Map<String, List<Map<String, dynamic>>> forecastMap = {};
        for (var entry in list) {
          final dtTxt = entry['dt_txt'];
          final DateTime dateTime = DateTime.parse(dtTxt);
          final dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';

          if (!forecastMap.containsKey(dateStr)) {
            forecastMap[dateStr] = [];
          }

          forecastMap[dateStr]!.add({
            'description': entry['weather'][0]['description'],
            'temperature': entry['main']['temp'],
          });
        }

        setState(() {
          _forecastData = forecastMap.entries.map((entry) {
            final date = entry.key;
            final dailyData = entry.value;
            final avgTemp = dailyData.map((e) => e['temperature'] as double).reduce((a, b) => a + b) / dailyData.length;
            final description = dailyData.map((e) => e['description']).join(', ');
            return {
              'date': date,
              'description': description,
              'temperature': avgTemp,
            };
          }).toList();
        });

        _checkWeatherAlerts(latitude, longitude, apiKey);
      } else {
        setState(() {
          _errorMessage = 'Erreur de chargement des données météo.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
      });
    }
  }

  Future<void> _checkWeatherAlerts(double latitude, double longitude, String apiKey) async {
    final url = 'https://api.openweathermap.org/data/2.5/alerts?lat=$latitude&lon=$longitude&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['alerts'] != null && data['alerts'].isNotEmpty) {
          final alert = data['alerts'].firstWhere((alert) => alert['event'].contains('Flood'), orElse: () => null);
          if (alert != null) {
            setState(() {
              _weatherAlert = 'Attention: ${alert['description']}';
            });
          } else {
            setState(() {
              _weatherAlert = 'Aucune alerte météo.';
            });
          }
        } else {
          setState(() {
            _weatherAlert = 'Aucune alerte météo.';
          });
        }
      } else {
        final error = json.decode(response.body);
        setState(() {
          _weatherAlert = 'Erreur de chargement des alertes météo: ${error['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _weatherAlert = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Météo sur 5 jours'),
        backgroundColor: Colors.blue, // AppBar bleu
      ),
      body: Column(
        children: <Widget>[
          if (_weatherAlert.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _weatherAlert,
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            ),
          Expanded(
            child: _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: TextStyle(fontSize: 24)))
                : ListView.builder(
                    itemCount: _forecastData.length,
                    itemBuilder: (context, index) {
                      final forecast = _forecastData[index];
                      final date = forecast['date'];
                      final description = forecast['description'];
                      final temperature = forecast['temperature'];

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16.0),
                          title: Text(
                            'Date: $date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Description: $description'),
                              SizedBox(height: 4),
                              Text('Température moyenne: ${temperature.toStringAsFixed(1)}°C'),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SafetyInfoPage()),
                );
              },
              child: Text("Ce qu'il faut savoir"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Bouton bleu
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ce qu\'il faut savoir'),
        backgroundColor: Colors.blue, // AppBar bleu
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSafetySection(
                context,
                icon: Icons.water_damage,
                title: 'Que faire en cas d\'inondation :',
                tips: [
                  'Évitez de marcher ou de conduire dans les zones inondées.',
                  'Montez à un endroit sûr et plus élevé.',
                  'Suivez les consignes des autorités locales.',
                ],
              ),
              SizedBox(height: 16),
              _buildSafetySection(
                context,
                icon: Icons.terrain,
                title: 'Que faire en cas de tremblement de terre :',
                tips: [
                  'Abritez-vous sous un meuble solide.',
                  'Éloignez-vous des fenêtres et des objets susceptibles de tomber.',
                  'Restez à l\'intérieur jusqu\'à la fin des secousses.',
                ],
              ),
              // Ajoutez d'autres sections pour d'autres catastrophes si nécessaire
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetySection(BuildContext context,
      {required IconData icon, required String title, required List<String> tips}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tips.map((tip) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
