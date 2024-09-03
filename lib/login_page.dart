import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'admin_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog(
        'Champs manquants',
        'Veuillez remplir tous les champs.',
      );
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorDialog(
        'Email invalide',
        'Veuillez entrer une adresse email valide.',
      );
      return;
    }

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = credential.user!.uid;
      DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$uid");

      final snapshot = await userRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);

        if (userData.containsKey('isAdmin') && userData['isAdmin'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminPage()),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/user', arguments: userData);
        }
      } else {
        _showErrorDialog(
          'Données non trouvées',
          'Aucune donnée disponible pour cet utilisateur.',
        );
      }

    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException caught: ${e.code}');
      String errorMessage;
      
      switch (e.code) {
        case 'auth/invalid-email':
          errorMessage = 'L\'adresse email fournie est invalide. Veuillez vérifier votre email et essayer à nouveau.';
          break;
        case 'auth/user-not-found':
          errorMessage = 'Aucun utilisateur trouvé avec cet email. Assurez-vous que l\'email est correct ou inscrivez-vous si vous n\'avez pas de compte.';
          break;
        case 'auth/wrong-password':
          errorMessage = 'Le mot de passe fourni est incorrect. Veuillez vérifier le mot de passe et réessayer.';
          break;
        case 'auth/too-many-requests':
          errorMessage = 'Trop de tentatives de connexion. Veuillez patienter quelques minutes avant de réessayer.';
          break;
        case 'auth/invalid-credential':
          errorMessage = 'Les informations d\'identification fournies sont invalides. Veuillez vérifier votre email et mot de passe.';
          break;
        default:
          errorMessage = 'Une erreur inconnue est survenue. Veuillez réessayer plus tard.';
          break;
      }

      _showErrorDialog(
        'Erreur de connexion',
        errorMessage,
      );
    } catch (e) {
      _showErrorDialog(
        'Erreur inconnue',
        'Une erreur inconnue est survenue. Veuillez réessayer.',
      );
    }
  }

  bool _isValidEmail(String email) {
    // Simple validation for email format
    RegExp emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegExp.hasMatch(email);
  }

  void _sendPasswordResetEmail() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorDialog(
        'Champs manquants',
        'Veuillez entrer votre adresse email.',
      );
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorDialog(
        'Email invalide',
        'Veuillez entrer une adresse email valide.',
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showErrorDialog(
        'Réinitialisation du mot de passe',
        'Un e-mail de réinitialisation du mot de passe a été envoyé à votre adresse.',
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'auth/invalid-email':
          errorMessage = 'L\'adresse email fournie est invalide.';
          break;
        case 'auth/user-not-found':
          errorMessage = 'Aucun utilisateur trouvé avec cet email.';
          break;
        default:
          errorMessage = 'Une erreur inconnue est survenue. Veuillez réessayer plus tard.';
          break;
      }

      _showErrorDialog(
        'Erreur',
        errorMessage,
      );
    } catch (e) {
      _showErrorDialog(
        'Erreur inconnue',
        'Une erreur inconnue est survenue. Veuillez réessayer.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  flex: 4, // 40% de la hauteur de l'écran pour l'image du haut
                  child: ClipRRect(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/image_background.jpg'), // Votre image de fond
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 6, // 60% de la hauteur de l'écran pour le bas
                  child: Container(
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(50.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/signup'); // Logique pour l'inscription
                          },
                          icon: Icon(Icons.person_add, color: Colors.blue),
                          label: Text(
                            'Inscription',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _sendPasswordResetEmail,
                            child: Text(
                              'Mot de passe oublié?',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _login,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                            child: Text('Se connecter', style: TextStyle(fontSize: 18, color: Colors.white)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
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
            ),
          ),
        ],
      ),
    );
  }
}
