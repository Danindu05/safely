import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogoutService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign out user
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();

      // Navigate to Login Screen after logout
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login', // Make sure this route exists in your app
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logout failed: ${e.toString()}"),
        ),
      );
    }
  }

  /// Show confirmation dialog before logout
  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              signOut(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}