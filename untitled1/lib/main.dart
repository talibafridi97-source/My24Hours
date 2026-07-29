import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Sigin_Screen.dart';
import 'firebase_options.dart'; // Is line ko add karna zaroori hai

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase ko initialize karna zaroori hai
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SiginScreen(),
    );
  }
}
