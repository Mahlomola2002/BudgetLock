import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailVerificationScreen extends StatefulWidget {
  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isEmailVerified = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
  }

  Future<void> _checkEmailVerified() async {
    User? user = _auth.currentUser;
    await user!.reload();
    setState(() {
      _isEmailVerified = user.emailVerified;
    });
  }

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    await user!.sendEmailVerification();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Email'),
      ),
      body: Center(
        child: _isEmailVerified
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Email verified!'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    child: Text('Go to your account'),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Please verify your email address.'),
                  if (_isLoading)
                    CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _sendVerificationEmail,
                      child: Text('Resend Verification Email'),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkEmailVerified,
                    child: Text('I have verified'),
                  ),
                ],
              ),
      ),
    );
  }
}
