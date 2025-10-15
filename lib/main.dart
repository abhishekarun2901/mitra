import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';       // Elder login/auth screen
import 'caregiver_dashboard.dart'; // Caregiver dashboard

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const ElderlyCareApp());
}

class ElderlyCareApp extends StatelessWidget {
  const ElderlyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elderly Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        useMaterial3: true,
      ),
      // Landing page: choose Elder or Caregiver
      home: const RoleSelectionScreen(),
    );
  }
}

// ------------------- Role Selection Screen -------------------
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Role")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Who are you?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // Elder button -> Login Screen
            ElevatedButton.icon(
              icon: const Icon(Icons.person, size: 28),
              label: const Text("Elder", style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.teal,
              ),
              onPressed: () => _navigateTo(context, const AuthWrapper()),
            ),
            const SizedBox(height: 20),
            // Caregiver button -> Dashboard
            ElevatedButton.icon(
              icon: const Icon(Icons.people, size: 28),
              label: const Text("Caregiver", style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.orangeAccent.shade700,
              ),
              onPressed: () =>
                  _navigateTo(context, const CaregiverDashboard()),
            ),
          ],
        ),
      ),
    );
  }
}
