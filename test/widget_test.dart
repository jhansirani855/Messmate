import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:messmate/screens/login_screen.dart';
// make sure this file exists in lib/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for Web and other platforms
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
