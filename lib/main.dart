import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'package:firebase_core/firebase_core.dart';





void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter(); // Initialize Hive
  await Hive.openBox('userBox'); // Open box
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto-fill Login',
      debugShowCheckedModeBanner: false,
      home: AuthGate(), // Always go to login
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // updates on login/logout
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return const HomePage(); // ✅ User is logged in
        } else {
          return const LoginPage(); // 🔒 Not logged in
        }
      },
    );
  }
}
