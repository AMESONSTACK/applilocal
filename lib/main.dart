import 'user_home_page.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'user_page.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'describ.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'user_model.dart';
import 'package:latlong2/latlong.dart';
import 'acceuil.dart';
import 'profil.dart';
//import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
   //OneSignal.initialize('455830c9-53e0-4883-8996-91f60a041603');
   //OneSignal.Notifications.requestPermission(true);  
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserModel(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/acceuil', // Démarre avec la page de création de compte
      routes: <String, WidgetBuilder>{
        '/signup': (context) => SignupPage(),
        '/acceuil': (context)=> WelcomePage (),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/user': (context) => UserPage(),
        '/admin': (context) => AdminPage(),
        '/userh': (context) => UserHomePage(),
        '/profil': (context) => ProfilePage(),
        '/describ': (context) {
             final LatLng markerPosition = ModalRoute.of(context)!.settings.arguments as LatLng;
          final LatLng draggableMarkerPosition = markerPosition; // Si draggableMarkerPosition n'est pas passé, utilisez markerPosition

          return NextPage(
            draggableMarkerPosition: draggableMarkerPosition,
            markerPosition: markerPosition,
          );
        },
      },
    );
  }
}
