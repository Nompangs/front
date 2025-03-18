import 'package:flutter/material.dart';
import 'login_screen.dart'; // Import LoginScreen

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(
                'assets/profile.png',
              ), // Adjust path as needed
            ),
            SizedBox(height: 16),

            // User ID Display
            Text(
              "User ID: user12345",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 20),

            // Logout Button
            ElevatedButton(
              onPressed: () {
                _logout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text("Logout", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    // Navigate to Login Screen and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false, // This removes all previous screens
    );
  }
}
