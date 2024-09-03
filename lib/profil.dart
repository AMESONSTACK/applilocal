import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');
  final DatabaseReference _incidentsRef = FirebaseDatabase.instance.ref().child('incidents');
  final ImagePicker _picker = ImagePicker();
  User? _currentUser;
  Map<dynamic, dynamic>? _userData;
  File? _imageFile;
  TextEditingController _usernameController = TextEditingController();
  int _incidentCount = 0;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _fetchUserData();
      _fetchIncidentCount();
    }
  }

  Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      try {
        DataSnapshot snapshot = await _usersRef.child(_currentUser!.uid).get();
        if (snapshot.exists) {
          setState(() {
            _userData = snapshot.value as Map<dynamic, dynamic>?;
            _usernameController.text = _userData!['username'] ?? "";
          });
        }
      } catch (e) {
        print("Erreur lors de la récupération des données utilisateur : $e");
      }
    }
  }

  Future<void> _fetchIncidentCount() async {
    if (_currentUser != null) {
      try {
        DataSnapshot snapshot = await _incidentsRef.orderByChild('userId').equalTo(_currentUser!.uid).get();
        if (snapshot.exists) {
          setState(() {
            _incidentCount = snapshot.children.length;
          });
        } else {
          setState(() {
            _incidentCount = 0;
          });
        }
      } catch (e) {
        print("Erreur lors de la récupération des incidents : $e");
      }
    } else {
      setState(() {
        _incidentCount = 0;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile != null && _currentUser != null) {
      try {
        String fileName = _currentUser!.uid + '_profile.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$fileName');
        UploadTask uploadTask = storageRef.putFile(_imageFile!);

        TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await _usersRef.child(_currentUser!.uid).update({'imageUrl': downloadUrl});
        _fetchUserData();
      } catch (e) {
        print("Erreur lors du téléchargement de l'image : $e");
      }
    }
  }

  Future<void> _updateUsername() async {
    if (_usernameController.text.isNotEmpty && _currentUser != null) {
      try {
        await _usersRef.child(_currentUser!.uid).update({'username': _usernameController.text});
        _fetchUserData();
      } catch (e) {
        print("Erreur lors de la mise à jour du nom d'utilisateur : $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Profil'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _userData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _userData!['imageUrl'] != null && _userData!['imageUrl'].isNotEmpty
                          ? NetworkImage(_userData!['imageUrl'])
                          : AssetImage('assets/images/image.png') as ImageProvider,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: "Nom d'utilisateur",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _updateUsername(),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _updateUsername,
                    child: Text('Mettre à jour le nom d\'utilisateur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 30),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileInfoRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: _currentUser!.email ?? "Non disponible",
                          ),
                          Divider(height: 20, thickness: 1),
                          ProfileInfoRow(
                            icon: Icons.report,
                            label: 'Nombre d\'incidents signalés',
                            value: _incidentCount.toString(),
                          ),
                          Divider(height: 20, thickness: 1),
                          ProfileInfoRow(
                            icon: Icons.phone,
                            label: 'Téléphone',
                            value: _userData!['phone'] ?? "Non disponible",
                          ),
                          Divider(height: 20, thickness: 1),
                          ProfileInfoRow(
                            icon: Icons.block,
                            label: 'Statut de suspension',
                            value: _userData!['suspended'] == true
                                ? "Suspendu jusqu'au ${_userData!['suspendedUntil']}"
                                : "Actif",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 28),
        SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
