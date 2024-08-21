// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, prefer_const_literals_to_create_immutables

import 'package:budget_lock/screens/chatbot.dart';
import 'package:budget_lock/screens/emailverification.dart';
import 'package:budget_lock/screens/login_screen.dart';
import 'package:budget_lock/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'screens/home.dart';
// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, prefer_const_literals_to_create_immutables
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Initialize Firebase for Web
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyB_fJyZrgVUQGHqqaeP0pj6BcmZOSU0rsc",
        authDomain: "budgetlock-912ac.firebaseapp.com",
        projectId: "budgetlock-912ac",
        storageBucket: "budgetlock-912ac.appspot.com",
        messagingSenderId: "753165604601",
        appId: "1:753165604601:web:931027a787c8ea48a73428",
        measurementId: "G-L8PCEYM3T7",
      ),
    );
  } else {
    // Initialize Firebase for Mobile (Android/iOS)
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    HomeScreen(),
    DashboardScreen(),
    ChatBotScreen(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/sign-up': (context) => SignUpScreen(),
        '/email-verification': (context) => EmailVerificationScreen(),
        '/home': (context) => HomeWrapper(), // Wrapper for home with navigation
      },
    );
  }
}

// Wrapper for Home with Navigation
class HomeWrapper extends StatefulWidget {
  @override
  _HomeWrapperState createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    HomeScreen(),
    DashboardScreen(),
    ChatBotScreen(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _children,
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 24.0),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard, size: 32.0), // Larger size
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat, size: 24.0),
            label: 'ChatBot',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Dashboard Screen',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
