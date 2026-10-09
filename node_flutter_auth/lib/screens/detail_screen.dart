import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class DetailScreen extends StatelessWidget {
  final String? email;
  final String? name;

  const DetailScreen({
    super.key,
    this.email,
    this.name,
  });

  // ================= LOGOUT =================

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');

    print('================================');
    print('LOGOUT SUCCESSFUL');
    print('JWT TOKEN DELETED');
    print('================================');

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // ================= APP BAR =================

      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),

      // ================= PROFILE BODY =================

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              // PROFILE ICON
              const CircleAvatar(
                radius: 55,
                backgroundColor: Colors.deepPurple,

                child: Icon(
                  Icons.person,
                  size: 65,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // PROFILE TITLE
              const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // NAME
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.person,
                    color: Colors.deepPurple,
                  ),

                  title: const Text(
                    'Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    name ?? 'No name available',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // EMAIL
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.email,
                    color: Colors.deepPurple,
                  ),

                  title: const Text(
                    'Email',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    email ?? 'No email available',
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // LOGOUT BUTTON
              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  onPressed: () {
                    logout(context);
                  },

                  icon: const Icon(Icons.logout),

                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,

                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}