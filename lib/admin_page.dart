import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Pour formater la date
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';


class AdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bienvenue Admin!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            _buildAdminButton(
              context,
              label: 'Dashboard',
              icon: Icons.dashboard,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardPage()),
                );
              },
            ),
            SizedBox(height: 16),
            _buildAdminButton(
              context,
              label: 'Gérer Utilisateurs',
              icon: Icons.group,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageUsersPage()),
                );
              },
            ),
            SizedBox(height: 16),
            _buildAdminButton(
              context,
              label: 'Gérer Incidents',
              icon: Icons.report,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageIncidentsPage()),
                );
              },
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                _showLogoutDialog(context);
              },
              child: Text('Déconnexion'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onPressed}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label, style: TextStyle(fontSize: 18)),
        onTap: onPressed,
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
    );
  }

void _signOut(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
  // Méthode pour afficher le dialogue de déconnexion
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la déconnexion'),
          content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialogue
              },
            ),
            TextButton(
              child: Text('Déconnexion'),
               onPressed: () {
                Navigator.of(context).pop();
                _signOut(context);
              }, // Retour à la première page
            ),
          ],
        );
      },
    );
  }
}

class ManageUsersPage extends StatefulWidget {
  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gérer Utilisateurs'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: StreamBuilder(
        stream: _usersRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.snapshot.value != null) {
              final usersMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

              // Convert Map to a list of entries
              final filteredUsers = usersMap.entries.where((entry) {
                final email = entry.value['email'] as String;
                return _searchQuery.isEmpty || email.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              return ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final entry = filteredUsers[index];
                  String key = entry.key;
                  Map<dynamic, dynamic> user = entry.value;

                  return _buildUserTile(context, user, key);
                },
              );
            } else {
              return Center(child: Text('No users found.'));
            }
          } else if (snapshot.hasError) {
            return Center(child: Text('An error occurred.'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, Map<dynamic, dynamic> user, String key) {
    final isSuspended = user['suspended'] ?? false;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4.0,
          ),
        ],
      ),
      child: ListTile(
        title: Text(user['email']),
        subtitle: Text(isSuspended ? 'Suspended' : 'Active'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSuspended) 
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.green),
                onPressed: () {
                  _showReactivateConfirmationDialog(context, key);
                },
              ),
            IconButton(
              icon: Icon(Icons.block, color: Colors.orange),
              onPressed: () {
                _showSuspendConfirmationDialog(context, key);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(context, key);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String key) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text("Voulez vous supprimer l'utilisateur?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _deleteUser(key);
                Navigator.of(context).pop();
              },
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _showSuspendConfirmationDialog(BuildContext context, String key) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmer Suspension'),
          content: Text("Voulez vous supprimez l\'utilisateur"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _suspendUser(key);
                Navigator.of(context).pop();
              },
              child: Text('Suspend'),
            ),
          ],
        );
      },
    );
  }

  void _showReactivateConfirmationDialog(BuildContext context, String key) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmer la Reactivation'),
          content: Text("Voulez vous réactivez l\'utilisateur?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _reactivateUser(key);
                Navigator.of(context).pop();
              },
              child: Text('Reactiver'),
            ),
          ],
        );
      },
    );
  }

  void _deleteUser(String key) {
    _usersRef.child(key).remove();
  }

  void _suspendUser(String key) {
    final now = DateTime.now();
    final suspendedUntil = now.add(Duration(days: 3));
    final suspendedUntilStr = DateFormat('yyyy-MM-ddTHH:mm:ss').format(suspendedUntil);

    _usersRef.child(key).update({
      'suspended': true,
      'suspendedUntil': suspendedUntilStr,
    }).then((_) {
      print('User suspended successfully');
    }).catchError((error) {
      print('Error suspending user: $error');
    });
  }

  void _reactivateUser(String key) {
    _usersRef.child(key).update({
      'suspended': false,
      'suspendedUntil': null,
    }).then((_) {
      print('User reactivated successfully');
    }).catchError((error) {
      print('Error reactivating user: $error');
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chercher utilisateurs'),
          content: TextField(
            decoration: InputDecoration(hintText: 'Entre votre email'),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}


class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');
  final DatabaseReference _incidentsRef = FirebaseDatabase.instance.ref().child('incidents');

  int _userCount = 0;
  int _suspendedUserCount = 0;
  int _incidentCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() {
    _usersRef.once().then((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _userCount = data.length;
          _suspendedUserCount = data.values.where((user) => user['suspended'] == true).length;
        });
      }
    });

    _incidentsRef.once().then((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _incidentCount = data.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCard('Total des Utilisateurs', _userCount, Icons.people,),
            _buildStatCard('Utilisateurs Suspendu', _suspendedUserCount, Icons.person_off),
            _buildStatCard('Total des Incidents', _incidentCount, Icons.report),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.blue),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          count.toString(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ),
    );
  }
}


class ManageIncidentsPage extends StatefulWidget {
  @override
  _ManageIncidentsPageState createState() => _ManageIncidentsPageState();
}

class _ManageIncidentsPageState extends State<ManageIncidentsPage> {
  final DatabaseReference _incidentsRef = FirebaseDatabase.instance.ref().child('incidents');
  Map<String, int> _incidentCountPerType = {};
  Map<int, int> _incidentCountPerMonth = {};
  Map<int, int> _incidentCountPerYear = {};
  String _filterType = 'Month';

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
  }

  Future<void> _fetchIncidents() async {
    _incidentsRef.once().then((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final typeCounts = <String, int>{};
        final monthCounts = <int, int>{};
        final yearCounts = <int, int>{};

        data.forEach((key, value) {
          final incident = value as Map<dynamic, dynamic>;
          String type = incident['incidentType'] ?? 'Unknown';
          DateTime date = DateTime.tryParse(incident['timestamp'] ?? '') ?? DateTime.now();
          int month = date.month;
          int year = date.year;

          // Count by type
          typeCounts[type] = (typeCounts[type] ?? 0) + 1;

          // Count by month
          monthCounts[month] = (monthCounts[month] ?? 0) + 1;

          // Count by year
          yearCounts[year] = (yearCounts[year] ?? 0) + 1;
        });

        setState(() {
          _incidentCountPerType = typeCounts;
          _incidentCountPerMonth = monthCounts;
          _incidentCountPerYear = yearCounts;
        });
      }
    });
  }

  List<BarChartGroupData> _generateBarGroups() {
    List<BarChartGroupData> barGroups = [];

    if (_filterType == 'Type') {
      List<String> types = _incidentCountPerType.keys.toList();
      List<int> counts = _incidentCountPerType.values.toList();

      for (int i = 0; i < types.length; i++) {
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: counts[i].toDouble(),
                color: Colors.blue,
                width: 16,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: counts.reduce((a, b) => a > b ? a : b).toDouble(),
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
            ],
          ),
        );
      }
    } else if (_filterType == 'Month') {
      for (int month = 1; month <= 12; month++) {
        barGroups.add(
          BarChartGroupData(
            x: month,
            barRods: [
              BarChartRodData(
                toY: _incidentCountPerMonth[month]?.toDouble() ?? 0.0,
                color: Colors.green,
                width: 16,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: _incidentCountPerMonth.values.isNotEmpty ? _incidentCountPerMonth.values.reduce((a, b) => a > b ? a : b).toDouble() : 1.0,
                  color: Colors.green.withOpacity(0.1),
                ),
              ),
            ],
          ),
        );
      }
    } else if (_filterType == 'Year') {
      List<int> years = _incidentCountPerYear.keys.toList();
      List<int> counts = _incidentCountPerYear.values.toList();

      for (int i = 0; i < years.length; i++) {
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: counts[i].toDouble(),
                color: Colors.red,
                width: 16,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: counts.reduce((a, b) => a > b ? a : b).toDouble(),
                  color: Colors.red.withOpacity(0.1),
                ),
              ),
            ],
          ),
        );
      }
    }

    return barGroups;
  }

  void _changeFilter(String filterType) {
    setState(() {
      _filterType = filterType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Incidents'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  _changeFilter('Month');
                },
                child: Text('Mois'),
              ),
              ElevatedButton(
                onPressed: () {
                  _changeFilter('Year');
                },
                child: Text('Année'),
              ),
              ElevatedButton(
                onPressed: () {
                  _changeFilter('Type');
                },
                child: Text('Type'),
              ),
            ],
          ),
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BarChart(
                BarChartData(
                  barGroups: _generateBarGroups(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (_filterType == 'Month') {
                            return Text(DateFormat.MMM().format(DateTime(0, value.toInt())));
                          } else if (_filterType == 'Year') {
                            return Text(value.toInt().toString());
                          } else if (_filterType == 'Type') {
                            final types = _incidentCountPerType.keys.toList();
                            final index = value.toInt();
                            return Text(index < types.length ? types[index] : 'Unknown');
                          } else {
                            return Text(value.toString());
                          }
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String title = '';
                        if (_filterType == 'Month') {
                          title = DateFormat.MMMM().format(DateTime(0, group.x.toInt()));
                        } else if (_filterType == 'Year') {
                          title = group.x.toInt().toString();
                        } else if (_filterType == 'Type') {
                          final types = _incidentCountPerType.keys.toList();
                          final index = group.x.toInt();
                          title = index < types.length ? types[index] : 'Unknown';
                        }
                        return BarTooltipItem(
                          '$title\n',
                          TextStyle(color: Colors.white),
                          children: <TextSpan>[
                            TextSpan(
                              text: (rod.toY).toString(),
                              style: TextStyle(color: Colors.yellow),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => IncidentListPage()),
              );
            },
            child: Text('Voir Incidents'),
          ),
        ],
      ),
    );
  }
}
class IncidentListPage extends StatefulWidget {
  @override
  _IncidentListPageState createState() => _IncidentListPageState();
}

class _IncidentListPageState extends State<IncidentListPage> {
  final DatabaseReference _incidentsRef = FirebaseDatabase.instance.ref().child('incidents');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');
  String _searchQuery = '';
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text('Incident List'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _incidentsRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.snapshot.value != null) {
              final incidentsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

              // Filter incidents based on search query
              final filteredIncidents = incidentsMap.entries.where((entry) {
                final incident = entry.value as Map<dynamic, dynamic>;
                final incidentType = incident['incidentType']?.toString().toLowerCase() ?? '';
                final comment = incident['comment']?.toString().toLowerCase() ?? '';
                return incidentType.contains(_searchQuery.toLowerCase()) ||
                       comment.contains(_searchQuery.toLowerCase());
              }).toList();

              return ListView.builder(
                itemCount: filteredIncidents.length,
                itemBuilder: (context, index) {
                  String key = filteredIncidents[index].key as String;
                  Map<dynamic, dynamic> incident = filteredIncidents[index].value as Map<dynamic, dynamic>;

                  // Retrieve user details for each incident
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _fetchUserDetails(incident['userId']),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (userSnapshot.hasError) {
                        return Center(child: Text('Error loading user details.'));
                      } else if (userSnapshot.hasData) {
                        final userDetails = userSnapshot.data!;
                        return _buildIncidentCard(context, incident, key, userDetails);
                      } else {
                        return Center(child: Text('No user details found.'));
                      }
                    },
                  );
                },
              );
            } else {
              return Center(child: Text('No incidents found.'));
            }
          } else if (snapshot.hasError) {
            return Center(child: Text('An error occurred.'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchUserDetails(String? userId) async {
    if (userId == null) {
      return {};
    }

    try {
      final userSnapshot = await _usersRef.child(userId).get();
      if (userSnapshot.exists) {
        return Map<String, dynamic>.from(userSnapshot.value as Map<dynamic, dynamic>);
      } else {
        return {};
      }
    } catch (e) {
      print('Error fetching user details: $e');
      return {};
    }
  }

  Widget _buildIncidentCard(BuildContext context, Map<dynamic, dynamic> incident, String key, Map<String, dynamic> userDetails) {
    final incidentType = incident['incidentType']?.toString() ?? 'Unknown Type';
    final comment = incident['comment']?.toString() ?? 'No comment';
    final timestamp = incident['timestamp']?.toString() ?? '';
    final userEmail = userDetails['email'] ?? 'No email';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 5.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IncidentDetailsPage(incident: incident),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                _getIncidentIcon(incidentType),
                size: 40.0,
                color: _getIncidentColor(incidentType),
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incidentType,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      comment,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Date: ${_formatDate(timestamp)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'User Email: $userEmail',
                      style: TextStyle(color: Colors.grey[800], fontSize: 16),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.0),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showDeleteConfirmationDialog(context, key);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIncidentIcon(String incidentType) {
    switch (incidentType) {
      case 'Débris sur la route':
        return Icons.aod;
      case 'Inondation':
        return Icons.water;
      default:
        return Icons.warning;
    }
  }

  Color _getIncidentColor(String incidentType) {
    switch (incidentType) {
      case 'Débris sur la route':
        return Colors.orange;
      case 'Inondation':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  String _formatDate(String timestamp) {
    final date = DateTime.tryParse(timestamp);
    if (date != null) {
      return DateFormat('dd/MM/yyyy').format(date);
    } else {
      return 'Unknown date';
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String key) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this incident?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteIncident(key);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteIncident(String key) {
    _incidentsRef.child(key).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incident deleted successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete incident: $error')),
      );
    });
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
  List<LatLng> _routePoints = [];
  late DatabaseReference _commentsRef;
  Map<String, dynamic> _userDetails = {};

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
    _commentsRef = FirebaseDatabase.instance.ref().child('incidents/${widget.incident['id']}/comments');
    _fetchUserDetails();
  }

  Future<void> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
      if (_currentPosition != null) {
        await _fetchRoute();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchRoute() async {
    if (_currentPosition == null) return;

    final startLat = _currentPosition!.latitude;
    final startLng = _currentPosition!.longitude;
    final endLat = (widget.incident['location'] as Map<dynamic, dynamic>)['latitude']?.toDouble() ?? 0.0;
    final endLng = (widget.incident['location'] as Map<dynamic, dynamic>)['longitude']?.toDouble() ?? 0.0;

    final apiKey = '5b3ce3597851110001cf6248e07514fe354d41618952e73e1b6fcea0';
    final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$startLng,$startLat&end=$endLng,$endLat');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          _routePoints = route.map((point) => LatLng(point[1], point[0])).toList();
        });
      } else {
        print('Failed to load route data.');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchUserDetails() async {
    final snapshot = await _commentsRef.get();
    if (snapshot.exists) {
      final comments = snapshot.value as Map<dynamic, dynamic>;
      final userIds = comments.values.map((comment) => comment['userId']).toSet();

      for (var userId in userIds) {
        final userSnapshot = await FirebaseDatabase.instance.ref('users/$userId').get();
        if (userSnapshot.exists) {
          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          setState(() {
            _userDetails[userId] = userData;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double? latitude = (widget.incident['location'] as Map<dynamic, dynamic>)['latitude']?.toDouble();
    double? longitude = (widget.incident['location'] as Map<dynamic, dynamic>)['longitude']?.toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text('Incident Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incident Type',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    Text(
                      widget.incident['incidentType'] ?? 'Unknown',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Description',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    Text(
                      widget.incident['comment'] ?? 'No comment',
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Date',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    Text(
                      _formatDate(widget.incident['timestamp']),
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            latitude != null && longitude != null
                ? Container(
                    height: 300,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(latitude, longitude),
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 80.0,
                              height: 80.0,
                              point: LatLng(latitude, longitude),
                              child:  Icon(Icons.location_pin, color: Colors.red, size: 40.0),
                            ),
                          ],
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              color: Colors.blue,
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'Location data not available.',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
            SizedBox(height: 16.0),
            Text(
              'Comments',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            SizedBox(height: 8.0),
            StreamBuilder(
              stream: _commentsRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.snapshot.value != null) {
                    final commentsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: commentsMap.length,
                      itemBuilder: (context, index) {
                        final comment = commentsMap.values.elementAt(index) as Map<dynamic, dynamic>;
                        final userId = comment['userId'];
                        final userDetails = _userDetails[userId] ?? {};
                        final userName = userDetails['username'] ?? 'Unknown user';
                        final userEmail = userDetails['email'] ?? 'No email';

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16.0),
                            title: Text(comment['comment'] ?? 'No comment'),
                            subtitle: Text('User: $userName\nEmail: $userEmail'),
                            trailing: Text(_formatDate(comment['timestamp'])),
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(child: Text('No comments found.'));
                  }
                } else if (snapshot.hasError) {
                  return Center(child: Text('An error occurred.'));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String timestamp) {
    final date = DateTime.tryParse(timestamp);
    if (date != null) {
      return DateFormat('dd MMMM yyyy').format(date);
    } else {
      return 'Unknown date';
    }
  }
}

