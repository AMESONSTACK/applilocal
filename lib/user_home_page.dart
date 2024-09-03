import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class UserHomePage extends StatefulWidget {
  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  Position? _currentPosition;
  LatLng _markerPosition = LatLng(0.0, 0.0); // Position initiale du marqueur
  LatLng _draggableMarkerPosition = LatLng(0.0, 0.0); // Position du marqueur déplaçable

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Afficher un message ou demander à l'utilisateur d'activer les services de localisation
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          // Afficher un message ou guider l'utilisateur pour accorder la permission
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = position;
        _markerPosition = LatLng(position.latitude, position.longitude);
        _draggableMarkerPosition = LatLng(position.latitude, position.longitude); // Initialiser le marqueur déplaçable
      });
    } catch (e) {
      // Gérer les exceptions et afficher des messages d'erreur si nécessaire
      print('Erreur lors de l\'obtention de la position : $e');
    }
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmer l\'annulation'),
          content: Text('Êtes-vous sûr de vouloir annuler ? Tous les changements seront perdus.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
                Navigator.pushNamed(context, '/user'); // Retourner à la page précédente
              },
              child: Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps'),
        backgroundColor: Colors.blue,
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _markerPosition,
                    initialZoom: 15, // Ajuster le niveau de zoom
                    onTap: (tapPosition, point) {
                      setState(() {
                        _draggableMarkerPosition = point; // Mettre à jour la position du marqueur déplaçable
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _markerPosition,
                          width: 80,
                          height: 80,
                          child:  Icon(Icons.location_pin, color: Colors.red, size: 40),
                        ),
                        Marker(
                          point: _draggableMarkerPosition,
                          width: 80,
                          height: 80,
                         child:  GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _draggableMarkerPosition = LatLng(
                                  _draggableMarkerPosition.latitude + details.delta.dy * 0.0001,
                                  _draggableMarkerPosition.longitude + details.delta.dx * 0.0001,
                                ); // Déplacer le marqueur
                              });
                            },
                            child: Icon(Icons.location_on, color: Colors.green, size: 40),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context, '/describ',
                        arguments: _draggableMarkerPosition, // Envoyer la position du marqueur déplaçable
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.navigate_next, size: 24),
                        SizedBox(width: 8),
                        Text('Suivant'),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: ElevatedButton(
                    onPressed: _showCancelConfirmationDialog,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                       Icon(Icons.cancel, size: 24),
                        SizedBox(width: 8),
                        Text('Annuler'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
