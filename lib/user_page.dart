/*import 'package:flutter/material.dart';
import 'login_page.dart';


class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Récupérer les données utilisateur passées en argument
    final Map<String, dynamic> userData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    void _signOut(BuildContext context) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }

    void _showSignOutConfirmationDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirmation'),
            content: Text('Are you sure you want to sign out?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(); // Ferme le dialogue
                },
              ),
              TextButton(
                child: Text('Sign Out'),
                onPressed: () {
                  Navigator.of(context).pop(); // Ferme le dialogue
                  _signOut(context); // Déconnecte l'utilisateur
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
          SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _showSignOutConfirmationDialog(context),
              child: Text('Déconnexion'),
            ),
        ],
      ),
      body: 
      
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('User Data:', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            //Text('Name: ${userData['name']}'),
            Text('Email: ${userData['email']}'),
            // Afficher plus de données utilisateur si nécessaire
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/userh'),
              child: Text('Signaler incident'),
              style: ElevatedButton.styleFrom(
                backgroundColor:Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
              )
            ),
            
          ],
        ),
      ),
    );
  }
}*/
import 'package:applilocali/profil.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'wheater_page.dart';
//import 'detailsinci.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'route_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';




class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final DatabaseReference _incidentsRef = FirebaseDatabase.instance.ref().child('incidents');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');

  List<Map<dynamic, dynamic>> _incidents = [];
    late RouteService _routeService;
    
  @override
  void initState() {
    super.initState();
    _fetchIncidents();
    _routeService = RouteService(); // Initialisez _routeService ici
   
  }

  Future<void> _fetchIncidents() async {
    try {
      DataSnapshot snapshot = await _incidentsRef.get();

      if (snapshot.exists) {
        List<Map<dynamic, dynamic>> incidentsList = [];
        Map<dynamic, dynamic> incidentsData = snapshot.value as Map<dynamic, dynamic>;
        incidentsData.forEach((key, value) {
          incidentsList.add(value);
        });

        setState(() {
          _incidents = incidentsList;
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération des incidents : $e");
    }
  }

  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final result = await _routeService.getRoute([
      [start.longitude, start.latitude],
      [end.longitude, end.latitude]
    ]);

    if (result != null && result.containsKey('routes') && result['routes'].isNotEmpty) {
      final route = result['routes'][0];
      final coordinates = route['geometry']['coordinates'] as List<dynamic>;

      return coordinates.map((coord) {
        return LatLng(coord[1], coord[0]);
      }).toList();
    }
    return [];
  }

  Future<bool> _checkIfUserIsSuspended() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("Aucun utilisateur connecté");
        return false;
      }

      String uid = user.uid;

      DataSnapshot snapshot = await _usersRef.child(uid).get();

      if (snapshot.exists) {
        Map<dynamic, dynamic>? userData = snapshot.value as Map<dynamic, dynamic>?;

        if (userData != null && userData.containsKey('suspended')) {
          return userData['suspended'] == true;
        }
      } else {
        print("Aucune donnée trouvée pour l'utilisateur $uid");
      }
    } catch (e) {
      print("Erreur lors de la récupération des données : $e");
    }
    return false;
  }

  void _signOut(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _showSignOutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Vous êtes sur de vouloir vous déconnectez?'),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Deconnexion'),
              onPressed: () {
                Navigator.of(context).pop();
                _signOut(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showSuspendedMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Access Denied'),
          content: Text('Vous ne pouvez pas signaler un incident car vous êtes suspendu.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static const appBarHeight = kToolbarHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Incidents'),
        backgroundColor: Colors.blueAccent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          SizedBox(width: 20),
          ElevatedButton(
            onPressed: () => _showSignOutConfirmationDialog(context),
            child: Text('Déconnexion'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.red, // Couleur du texte
            ),
          ),
          SizedBox(width: 10),
        ],
        automaticallyImplyLeading: false,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              color: Colors.blueAccent,
              height: appBarHeight,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                ),
                child: Center(
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                 ListTile(
                    title: Text('Voir la météo'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WeatherPage()),
                      );
                    },
                  ),
                  ListTile(
                    title: Text('Voir profil '),
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: _incidents.isEmpty
                  ? Center(child: Text('Aucun incident signalé.'))
                  :ListView.builder(
  itemCount: _incidents.length,
  itemBuilder: (context, index) {
    final incident = _incidents[index];
    final DateTime? date = incident['timestamp'] != null ? DateTime.parse(incident['timestamp']) : null;
    final formattedDate = date != null ? "${date.day}/${date.month}/${date.year}" : "Date non disponible";

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.0),
        title: Text(
          'Incident: ${incident['incidentType'] ?? "Type non disponible"}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${incident['comment'] ?? "Description non disponible"}'),
            SizedBox(height: 4),
            Text('Date: $formattedDate'),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IncidentDetailsPage(incident: incident),
            ),
          );
        },
      ),
    );
  },
)

            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    bool isSuspended = await _checkIfUserIsSuspended();
                    if (isSuspended) {
                      _showSuspendedMessage(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/userh');
                    }
                  },
                  child: Text('Signaler incident'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class IncidentDetailsPage extends StatefulWidget {
  final Map<dynamic, dynamic> incident;

  IncidentDetailsPage({required this.incident});

  @override
  _IncidentDetailsPageState createState() => _IncidentDetailsPageState();
}

class _IncidentDetailsPageState extends State<IncidentDetailsPage> {
  Position? _currentPosition;
  List<LatLng>? _route;
  final _commentController = TextEditingController();
  List<Map<dynamic, dynamic>>? _comments;

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
    _fetchRoute();
    _fetchComments();
  }

  Future<void> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchRoute() async {
    if (_currentPosition == null) return;

    final apiKey = '5b3ce3597851110001cf6248e07514fe354d41618952e73e1b6fcea0'; // Remplacez par ta clé API ORS
    final startLat = _currentPosition!.latitude;
    final startLng = _currentPosition!.longitude;
    final endLat = (widget.incident['location'] as Map<dynamic, dynamic>)['latitude'];
    final endLng = (widget.incident['location'] as Map<dynamic, dynamic>)['longitude'];

    final url = 'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$startLng,$startLat&end=$endLng,$endLat';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] == null || data['routes'].isEmpty) {
          throw Exception('Aucune route trouvée dans la réponse');
        }

        final route = data['routes'][0]['geometry']['coordinates'] as List<dynamic>;

        setState(() {
          _route = route.map((coord) => LatLng(coord[1], coord[0])).toList();
        });
      } else {
        throw Exception('Failed to load route');
      }
    } catch (e) {
      print('Erreur lors de la requête: $e');
      throw Exception('Failed to load route');
    }
  }

  Future<void> _fetchComments() async {
    final commentsRef = FirebaseDatabase.instance.ref().child('incidents/${widget.incident['id']}/comments');
    final snapshot = await commentsRef.get();

    if (snapshot.exists) {
      final fetchedComments = (snapshot.value as Map<dynamic, dynamic>).values.toList().cast<Map<dynamic, dynamic>>();

      // Fetch email addresses for each comment
      for (var comment in fetchedComments) {
        final userId = comment['userId'];
        final userSnapshot = await FirebaseDatabase.instance.ref().child('users/$userId').get();
        final email = userSnapshot.child('email').value as String?;

        comment['email'] = email ?? 'Utilisateur inconnu';
      }

      setState(() {
        _comments = fetchedComments;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final commentRef = FirebaseDatabase.instance.ref().child('incidents/${widget.incident['id']}/comments');
      await commentRef.push().set({
        'userId': user.uid,
        'comment': _commentController.text,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _commentController.clear();
      _fetchComments();
    } catch (e) {
      print('Erreur lors de l\'ajout du commentaire: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double? incidentLatitude = (widget.incident['location'] as Map<dynamic, dynamic>)['latitude']?.toDouble();
    double? incidentLongitude = (widget.incident['location'] as Map<dynamic, dynamic>)['longitude']?.toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de l\'incident'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.report, color: Colors.blue, size: 30),
                          SizedBox(width: 8.0),
                          Text(
                            'Type: ${widget.incident['incidentType']}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.0),
                      Text('Commentaire: ${widget.incident['comment']}'),
                      SizedBox(height: 8.0),
                      Text('Date: ${widget.incident['timestamp']}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              incidentLatitude != null && incidentLongitude != null
                  ? Container(
                      height: 300,
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(incidentLatitude, incidentLongitude),
                              initialZoom: 13.0,
                            ),
                            children: [
                              TileLayer(
                                tileProvider: CancellableNetworkTileProvider(),
                                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              ),
                              if (_route != null)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: _route!,
                                      strokeWidth: 4.0,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: [
                                  if (_currentPosition != null)
                                    Marker(
                                      width: 80.0,
                                      height: 80.0,
                                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                      child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 40.0),
                                    ),
                                  Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: LatLng(incidentLatitude, incidentLongitude),
                                    child: Icon(Icons.location_pin, color: Colors.red, size: 40.0),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        'Données de localisation non disponibles.',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
              SizedBox(height: 16.0),
              Card(
  elevation: 5,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  ),
  child: Padding(
    padding: EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _commentController,
          maxLines: null, // Permet d'agrandir la zone de texte si nécessaire
          decoration: InputDecoration(
            labelText: 'Ajouter un commentaire',
            hintText: 'Écrivez votre commentaire ici...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            prefixIcon: Icon(Icons.comment, color: Colors.blue),
          ),
        ),
        SizedBox(height: 8.0),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _addComment,
            icon: Icon(Icons.send, color: Colors.white),
            label: Text('Envoyer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),
SizedBox(height: 16.0),
if (_comments != null && _comments!.isNotEmpty)
  Card(
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commentaires',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          SizedBox(height: 8.0),
          Divider(color: Colors.grey[400]),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _comments!.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey[300]),
            itemBuilder: (context, index) {
              final comment = _comments![index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  comment['comment'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Par: ${comment['email']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: Text(
                  comment['timestamp'],
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          ),
        ],
      ),
    ),
  )
else
  Center(
    child: Text(
      'Aucun commentaire pour cet incident.',
      style: TextStyle(color: Colors.grey, fontSize: 16),
    ),
  ),

            ],
          ),
        ),
      ),
    );
  }
}
