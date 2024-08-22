// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:ui';
import 'package:budget_lock/screens/Reports.dart';
import 'package:budget_lock/screens/chatbot.dart';
import 'package:budget_lock/screens/emailverification.dart';
import 'package:budget_lock/screens/login_screen.dart';
import 'package:budget_lock/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'screens/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

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
    ReportsPage(),
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
      backgroundColor: Color.fromARGB(0, 30, 215, 96),
      body: IndexedStack(
        index: _currentIndex,
        children: _children,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(
              255, 3, 44, 19), // Fully transparent background
          borderRadius: BorderRadius.circular(50.0),
          boxShadow: [
            BoxShadow(
              blurRadius: 10.0,
              spreadRadius: 2.0,
              offset: Offset(5.0, 5.0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
          child: GNav(
            backgroundColor: const Color.fromARGB(
                255, 3, 44, 19), // Set the GNav background to transparent
            rippleColor: Colors.white, // tab button ripple color when pressed
            hoverColor: Colors.white, // tab button hover color
            haptic: true, // haptic feedback
            tabBorderRadius: 15,

            curve: Curves.easeOutExpo, // tab animation curves
            duration: Duration(milliseconds: 300), // tab animation duration
            gap: 8, // the tab button gap between icon and text
            color: Colors.white70, // unselected icon color
            activeColor: Colors.white, // selected icon and text color
            iconSize: 24, // tab button icon size
            tabBackgroundColor:
                Colors.white.withOpacity(0.1), // selected tab background color
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            onTabChange:
                onTabTapped, // Call the function to update _currentIndex
            tabs: [
              GButton(
                icon: Icons.home_filled,
                text: "Home",
              ),
              GButton(
                icon: Icons.dashboard,
                text: "Dashboard",
              ),
              GButton(
                icon: Icons.chat_bubble,
                text: "Chatbot",
              )
            ],
          ),
        ),
      ),
    );
  }
}
