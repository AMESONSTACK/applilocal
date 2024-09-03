import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
//import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'user_page.dart';



class NextPage extends StatefulWidget {
  final LatLng draggableMarkerPosition;

  NextPage({required this.draggableMarkerPosition, required LatLng markerPosition});

  @override
  _NextPageState createState() => _NextPageState();
}

class _NextPageState extends State<NextPage> {
  final TextEditingController _commentController = TextEditingController();
  XFile? _imageFile;
  String? _selectedIncident;

  // Liste des incidents
  final List<String> _incidents = [
    'Accident',
    'Débris sur la route',
    'Travaux',
    'Autre',
  ];

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);
    setState(() {
      _imageFile = image;
    });
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choisissez une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Prendre une photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choisir depuis la Galerie'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadImageToFirebaseStorage() async {
    if (_imageFile == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref().child('images/${DateTime.now().toIso8601String()}');
      final uploadTask = storageRef.putFile(File(_imageFile!.path));
      final snapshot = await uploadTask.whenComplete(() {});
      final imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Erreur lors de l\'upload de l\'image : $e');
      return null;
    }
  }

  Future<void> _saveDataToRealtimeDatabase(String imageUrl) async {
  final userId = getUserId();
  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Utilisateur non connecté.')));
    return;
  }

  await FirebaseDatabase.instance.ref().child('incidents').push().set({
    'userId': userId,
    'comment': _commentController.text,
    'imageUrl': imageUrl,
    'incidentType': _selectedIncident,
    'location': {
      'latitude': widget.draggableMarkerPosition.latitude,
      'longitude': widget.draggableMarkerPosition.longitude,
    },
    'timestamp': DateTime.now().toIso8601String(), // Enregistre la date et l'heure actuelles
  });
}

  Future<void> _sendNotificationToAllUsers() async {
    const String serverKey = 'QgAgUZudPdNttBLYucI2uCEV5apYNr6NBlXvaCQc'; // Remplacez par votre clé serveur FCM

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'to': '/topics/all',
          'notification': <String, dynamic>{
            'title': 'Incident signalé',
            'body': 'Un nouvel incident a été signalé.',
          },
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Notification envoyée avec succès');
      } else {
        print('Erreur lors de l\'envoi de la notification : ${response.body}');
      }
    } catch (e) {
      print('Exception lors de l\'envoi de la notification : $e');
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
                Navigator.of(context).pop(); // Retourner à la page précédente
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
        title: const Text('Détails du Trajet'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Carte en haut
          Container(
            height: 200, // Réduit la hauteur de la carte
            child: FlutterMap(
              options: MapOptions(
                initialCenter: widget.draggableMarkerPosition,
                initialZoom: 15, // Ajuster le niveau de zoom selon vos besoins
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.draggableMarkerPosition,
                      width: 80,
                      height: 80,
                      child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Espacement entre la carte et les sections
          SizedBox(height: 16),
          // Section pour choisir ou prendre une image et ajouter un commentaire
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Conteneur d'image
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 150,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(File(_imageFile!.path)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _imageFile == null
                            ? Center(
                                child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Conteneur pour commentaire et liste déroulante
                Expanded(
                  flex: 3,
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Conteneur de commentaire et liste déroulante regroupés
                        Container(
                          height: 150,
                          child: Column(
                            children: [
                              // Conteneur de commentaire
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _commentController,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Écrire un commentaire',
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              // Liste déroulante pour sélectionner l'incident
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedIncident,
                                  hint: Text('Sélectionner un incident'),
                                  items: _incidents.map((String incident) {
                                    return DropdownMenuItem<String>(
                                      value: incident,
                                      child: Text(incident),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedIncident = newValue;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
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
 ElevatedButton(
  onPressed: () async {
    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImageToFirebaseStorage();
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'upload de l\'image.')));
        return;
      }
    }

    await _saveDataToRealtimeDatabase(imageUrl ?? '');
    await _sendNotificationToAllUsers();  // Envoyer la notification après la sauvegarde
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Données sauvegardées avec succès !')));

    // Redirection vers la page `UserHomePage` après soumission
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => UserPage()),
      (Route<dynamic> route) => false,
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
      Text('Soumettre'),
    ],
  ),
),



          ],
        ),
      ),
    );
  }

  String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }
}
