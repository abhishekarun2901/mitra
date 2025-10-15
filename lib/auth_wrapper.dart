import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'phone_login_screen.dart'; // The screen for phone number input
// Your main app home screen
import 'profile_check_wrapper.dart'; // Import the new wrapper

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to the authentication state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the connection is waiting, show a loading indicator.
        // This is important for when the app first loads and Firebase is checking the auth status.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If data is present and the user is not null, they are signed in.
        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in, show the Home Screen.
          return const ProfileCheckWrapper();
        } else {
          // User is not signed in, show the Phone Login Screen.
          return const PhoneLoginScreen();
        }
      },
    );
  }
}