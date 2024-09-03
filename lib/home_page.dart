import 'package:flutter/material.dart';
import 'admin_page.dart';
import 'user_page.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, bool> args = ModalRoute.of(context)!.settings.arguments as Map<String, bool>;
    final bool isAdmin = args['isAdmin'] ?? false;

    if (isAdmin) {
      return AdminPage();
    } else {
      return UserPage();
    }
  }
}
