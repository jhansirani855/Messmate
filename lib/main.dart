import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDP-PS43lUsu7ifdWWlwV-PqVvLDJ4vm5E",
      authDomain: "messmate-2c3ec.firebaseapp.com",
      projectId: "messmate-2c3ec",
      storageBucket: "messmate-2c3ec.appspot.com",
      messagingSenderId: "885362451855",
      appId: "1:885362451855:web:6bb5d5dbe96eb73391d7fa",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MessMate',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.white, // white background for all screens
      ),
      home: AuthWrapper(),
    );
  }
}

// AuthWrapper decides which screen to show
class AuthWrapper extends StatelessWidget {
  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return HomeScreen(); // show home/login screen if not logged in
    } else {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return HomeScreen();
          }

          String role = snapshot.data!['role'] ?? 'user';
          if (role == 'admin') {
            return AdminDashboardScreen(); // removed const
          } else {
            return UserDashboardScreen(); // removed const
          }
        },
      );
    }
  }
}
